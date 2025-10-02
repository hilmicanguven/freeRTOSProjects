# Idle Task

kernel tarafından (scheduler) otomatik olarak üretilen task'tır. en düşük önceliğe sahiptir. diğer uygulamaların çalışmasını etkilemez. oluşturulmasının amacı CPU'da en azından bir tane task'ın çalışması içindir.

bir başka önemli kullanımı, **delete edilen task'lara ait belleğin de-allocate edilmesi de yine idle task tarafından yapılır.**

idle task içerisinde CPU'yu düşük güç moduna geçirmek için bir fonksiyon bağlanabilir. bir çeşit callback bağlanarak farklı bir işlem yaptırılması da mümkündür.

# Timer Services Task

eğer software timer kullanılacak ise, `configUSE_TIMERS` flasg'i ile belirlenir, bu da scheduler tarafından kernel başladığında oluşturulur. `xTimerCreateTimerTask` ile oluşturulur.

# Scheduler 

freeRTOS'da Scheduler iki parçanın bir araya gelmesiyle oluşur -> freeRTOS Generic Code (tasks.c) + Architecture SpecificCode (port.c)

## Arch Specific Code
    
Scheduling işlemini yapabilmek için bazı Kernek Interrupt Handler'ları oluşturmak gereklidir.
    
- `vPortSVCHandler` : İlk taskı başlatmak için kullanılır. SVC instruction'ı ile tetiklenir
- `xPortPendSVHandler` : PendSV System exception ile tetiklenen, Context Switch yapabilmke için gereklidir.
- `xPortSysTickHandler` : Periyodik tick üretmek için ve zaman hesaplaması yapabilmek için gereklidir. 

## `vTaskStartScheduler` Fonksiyonu

Scheduler'ı başlatmak için tek bir kere çağırılan fonksiyondur. Idle task'ı oluşturur. Sonrasında Arch specific initialization fonksiyonu çağırır (`xPortStartScheduler`)

### xPortStartScheduler
- SysTick Timer ı konfigüre eder ve hangi sıklıkta interrupt üretileceğini (birnevi sistemin time resolution'ı olarak da düşünebiliriz) belirler.
- PendSV ve Systick için interrupt priority belirler.
- SVC komutu ile SVCHandler'ı çağırır ve ilk task'ı başlatır (Assembly ile yapılır).

