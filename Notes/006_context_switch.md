# Context Switch

Context Switch : CPU'daki çalışan bir task'ın durdurulup diğer taskın çalıştırılması işlemidir.
RTOS'larda Scheduler tarafından yönetilir. freeRTOS'da `PendSVHandler`!!!.
pre-emptive bir scheduling yapılıyorsa, her bir sysTick intertrupt'da priorit'lere bakılır ve farklı bir task'a geçileceğine karar verilir. `taskTIELD()` manuel olarak switch işlemi yapılmak istenirse kullanılır.

## State of the Task

Task state'i dediğimizde -> "Core Registers of CPU" + "Task Stack Content" bilgilerini kastederiz.
Arm Cortex Mx Core Registers
- Low-High Registers, used for general purpose, function calls   ->  R0 ... R2
- Stack Registers (SP) -> PSP (User Task Stack Pointer) veya MSP (Kernel Stack Pointer) için kullanılır.
    - PSP, task's private stack. task içerisinde push/pop işlemleri bu register'ın gösterdiği alanda yapılır
    - MSP, kernel's private stack. ISR çalıştığı durumda push/pop bu register'ın gösterdiği alanda yapılır. Scheduler'da bu alanda çalışıyor elbette.
- PSR -> Program Status Register (negative flag, overflow flag)

Task'ların stack'leri ve TCB'ler Heap den yer ayrılarak belirlenir. Bunun haricinde Kernel Stack ve Global değişkenlerin saklandığı memory alanları vardır.

`xTaskCreate()` fonksiyonu çağırıldığında,
- TCB data strucutre'ı oluşturulur. `pxTopOfStack` field'ı stack adresinin başlangıcını gösterir.
- Stack bölgesi ayrılır.
- Task, ready task listesine koyulur.

## Task Switching-Out Procedure

Bir task'tan çıkıldığı durumda yapılan işlemler,

1. Processor Core Register'ları (R0, R1, R2, R3, R12, LR, PC, xPSR) **Task'ın private stack alanına** kayıt edilir. bu işlem, **__SysTick Interrupt'a girince otomatik CPU tarafından yapılır__**.
2. eğer C.S. gerekliyse PendSV Exception üretilir.
3. R4-R11, R14 register'ları **manuel olarak task's private stack memory'sine kayıt edilir.** PendSV Handler bunu bizim yerimize yapar.
4. PSP , TCB'nin ilk elemanına kayıt edilir. 
5. bir sonraki potansiyel task seçilir, `vTaskSwitchContext()`. seçerken en yüksek önceliğe sahip task'ı `taskSELECT_HIGHEST_PRIORITY_TASK()` ile bulabiliriz.

## Task Switching-In Procedure

Bir task'tan çıkıp diğerine girdiğimizde yapılan işlemler, 

1. bir önceki task'tan çıkarken hangi task'ın çalışacağını biliyoruz. bu yeni task'ın TCB'sine `pxCurrentTCB` ile ulaşabiliriz.
2. bu TCB'den, task'ın stack pointer'ine(ilk eleman) erişiriz ve PSP'ye kopyalarız.
3. R4-R11, R14 register değerlerini restore ederiz, pop ederiz.
4. PendSV Exception Handler'dan çıkış yapılır. bu adımda CPU tarafından diğer register'lar da restore edilir.