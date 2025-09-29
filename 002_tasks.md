/*

freeRTOS içerisinde birbirine paralel şekilde çalışacak iş parçalarını Task oluşturarak sağlarız.
ör. sensörden veri okuma, display ekranında sensçr değerinin güncellenmesi, kullanıcıdan gelen komutları işleme

1. task'ı oluşturma, çeşitli özelliklerini vererek -> task creation function "xTaskCreate"
2. task içerisinde yapılacak işlemleri yazdığımız fonksiyon(lar)ı oluşturma
    genellikle infinite loop'dan oluşur. terminate edilmediği sürece return etmez
    task içerisinde oluşturulan local değişkenler, Task'ın Stack bölgesinde oluşturulur.
    aynı fonksiyonu kullanan 2 Task için bu local değişken farklı stack'lerde tanımlanmış olur
    
- Task Creation

    BaseType_t xTaskCreate( TaskFunction_t pxTaskCode,
                                const char * const pcName,
                                const configSTACK_DEPTH_TYPE uxStackDepth,
                                void * const pvParameters,
                                UBaseType_t uxPriority,
                                TaskHandle_t * const pxCreatedTask )
    
    status = xTaskCreate(task1_handler, 
                        "Task-1", 
                        200, 
                        "Hello world from Task-1", 
                        2, 
                        &task1_handle);
                    

        - task handler  -> task için entry point noktasıdır
        - uxStackDepth  -> "word" biriminden stack boyutudur
        - pvParameters  -> task içerisine geçilecek parametredir
        - uxPriority    -> task öncelik değeridir
        - pxCreatedTask -> task için unique bir handler, numara, bilgisidir

        Not: UBaseType_t tipi, mimarinin kaç bit olduğuna göre değişen değişken türünü belirtmek için kullanılır
            32 bit MCU'da bu tip ile maksimum 32-bit genişliğinde bir değeri tutabiliriz

        - Task Priority
            task priority, task'ların çalışma önceliğini belirleyen sayısal değerdir.
            düşük priority değeri, daha yüksek önceliği gösterir.
            freeRTOSConfig.h içerisinde tanımlanan "configMAX_PRIORITIES" değeri ile aslında en düşük önceliğe ait değeri belirleriz
            farklı sayıda priority'e sahip task oluşturmak, system'e overhead ekler ve ekstra ram kullanımına sebep olur.

        Task başarılı ile oluşturulursa ready list'e yeni bir task eklenmiş olur.
        fonksiyonun return değeri status belirtir, eğer task create işlemi fail olursa bu değere bakılmalıdır
        geçersiz parametre verme, yeterli stack alanına sahip olamama gibi hatalar oluşabilir
        
Task'lar oluşturulduktan sonra, bunların schedule edilmesi gerekir.
elbette bunu bizim yerimize freeRTOS'un yapmasını sağlarız.
scheduler' da aslında basit bir kod parçasından başka bir şey değildir.
ancak normal koddan farklı olarak, işlemcide "privileged" olarak söylenen modda çalışır.
yani normal kodlara göre daha fazla yetkiye sahip olduğumuz bir moddur.
bazı instruction'lar yalnızca bu modda çalıştırılabilir.
işlemcinin bazı register'larına yalnızca bu modda erişebilir veya değiştirebiliriz.
scheduler başlatmak için ->  `vTaskStartScheduler` fonksiyonu çağırılır.
farklı scheduler politikaları mevcut. freeRTOSconfig.h içerisinde flag ile seçebiliriz.
    - pre-emptive scheduling
        pre-emption: bir task'ın farklı bir task için kendi işi bitmese dahi işlemciyi bırakmasıdır.
        kendisi tekrardan ready state'e döner.

        - round robin (cyclic) pre-emptive scheduling
            task'lar ready list'e eklenmiş haldedir. her bir task'ın sırası sanırım oluşturma sırasına göre belirlenir.
            tüm task'lar için ortak bir çalışma süresi belirlenir (time-slice) ve süresi bittiğinde diğer task'a geçer. bu time-slice duration'ı -> configTICK_RATE_HZ ile belirlenir.
            bu süreyi tutmak için "RTOS Tick Timer" kullanılır. farklı bir isimle "SysTick Timer"
            bu geçiş esnasında context switch işlemi olur (context switch: mevcut task'ın state'i ve durumu kayıt altına alınır, ihtiyaç halinde tekrar bu bilgilere bakarak kaldığı yerden çalışması sağlanır.)

        - priority based pre-emptive scheduling
            task'lar ready list'e eklenmiş haldedir. her bir task'ın sırası priority değerine göre belirlenir.
            en yüksek öncelikli task bitene kadar çalışır.

    - co-operative scheduling
        priority önemli değildir. Task kendisi çalışmasını bitirince CPU'yu salar (buna "yields" da denir)
        systick timer, scheduler'ı uyarmaz ya da bir girdisi olmaz.

`vTaskStartScheduler` fonksiyonu sonrasına kodda hiçbir ekleme yapmamak gereklidir çünkü kodun oraya ulaşmaması gerekir. eğer ulaşmış ise memory'de bir sıkıntnı olmuş heap patlamış olabilir.


Debug yapmak için kullanacağımız "print" fonksiyonalitesi için SWO pinlerinde yararlanırız. Sonrasında PC'de mesajları görürüz.
bunu sağlayan ITM(instrumentation ..) kullanılır. aslında bu da basitçe karakter bastırmak için kullanılır.

yine debugger için project settings -> debug sekmesi aslında birkaç ayar yapmak gerekli.
    serial wire viewer kullandığımız için enable etmek gerekir. uygun clock'u seçmek gerekir.
    st-link driver gerekli bunun kurulması gerekebilir.

"hello_world" projesi olarak 2 task oluşturup ikisi de kendi mesajlarını ITM aracılığı ile konsola bastırır.
aynı priority'e sahip oldukları için her ikiside time-slice sonrası kendisine sıra geldiğinde 
(birbirlerine öncelik sağlayamayacağı için sırayla çalışırlar)
ortak kaynak olan ITM'e kullanacak ve kendi mesajlarını gönderecek.
bu durumda konsolda içiçe geçmiş mesajları görürüz. bunu engellemek için bir çeşit lock-unlock mekanizması kullanabiliriz. bu tür mekanizmaları daha ileride kullanacağız.
şu an buna çözüm olarak, 
    - eğer pre-emption kapatırsak artık birbirlerini engellemeyecek ancak task2 hiç  çalışmayacaktır.
    - alternatif olarka co-operative scheduling seçersek sırası ile çalışabilirer.
        yani birinin çalışması için diğeri işini bitirince CPU'yu yield eder.
        böyle sıra sonraki task'a gelir. bunun için `taskYIELD()` fonksiyonunu kullanırlar

- Task Oluşturma Esnasında Memory-RAM Kullanımı
    discovery board için konuşacak olursak toplamda 128Kb boyutunda bir RAM'e sahibiz.
    bunun bir kısmı heap bir kısmı global data, static değişkenler için kullanılır.
    `configTOTAL_HEAP_SIZE` flag i bu heap boyutunu belirleyebiliriz.
    **task oluşturunca, TCB(Task Control Block -> bir task'a ait gerekli tüm bilgileri içinde tutan veri yapısıdır) ve task'a ait stack Heap de oluşturulur.**
    Stack'in adresini "PSP" register'ı ile takip edebiliriz.
    bunlara ek olarak semaphore, queue vb yapılar kullandıkça bunlar da heap de depolanır.
    bunlara dynamically created object olarak adlandırabiliriz.
    Heap dediğimiz şey de büyük bir array'den başka bir şey değil nihayetinde :)
    
    _Not: bir task static olarak oluşturulabilir, bu durumda global area section da oluşturulur_

Task Control Block

| Component                    | Description                                                                                 |
| ---------------------------- | ------------------------------------------------------------------------------------------- |
| **Task Stack Pointer**       | Points to the task’s current position in its stack. This is critical for context switching. |
| **Task Name**                | Human-readable name of the task (optional, used for debugging or monitoring).               |
| **Task Priority**            | The priority level of the task (used by the scheduler).                                     |
| **Task State**               | Ready, Running, Blocked, Suspended, etc.                                                    |
| **Stack Base & Stack Size**  | Information for checking stack overflows and for stack management.                          |
| **Task List Item**           | Used to place the task in various internal lists (e.g., ready list, delayed list).          |
| **Delay or Timeout Info**    | Tick count when the task should unblock.                                                    |
| **Task Notifications**       | Lightweight inter-task signaling mechanism.                                                 |
| **Event List Item**          | Used if the task is waiting on an event or queue.                                           |
| **TCB extension (optional)** | For things like MPU settings, tracing info, runtime stats.                                  |

*/