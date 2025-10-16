# Queues

Bir çeşit data structure'dır aslında. Belirli bir boyutta veri depolayabilir. FIFO şeklinde çalışan bir buffer'dır. (Klasik Head-Tail ve Enqueue-Dequeue)

Queue oluşturmak için aşağıdaki şekilde Queue handle tanımlamamızı yaparız. İleride göreceğimiz API'leri bu handle'lar aracılığı ile çağıracağız.
```cppcode
QueueHandle_t q_data;
QueueHandle_t q_print;
```

`xQueueCreate(...)` ile queue oluşturabilir. Return tipi handle'dır. kaç item tutacağı ve her birinin boyutunu input parametre olarak veririz.

`xQueueSendToFront(handle, item, timeout)` ile queue ya eleman ekleyebiliriz. timeout ise queue'nun full olması durumunda beklenecek maximum tick süresidir. tabi diğer bir seçenek boşalana kadar beklemektir, 0 verilerek. "port_MAX_DELAY" ile sonsuza kadar bekler. `xQueueSendToFront` ile de queue nun sonuna ekleyebiliriz. 

`xQueueSend()` ile de mesajlar queue ya gönderilir. **Önemli Not:** queue copy mesajların referansı ile değil de kopyalama ile gönderilir...parametre verirken adresini vermeyi unutmayınız.


`xQueueReceive(handle, buffer, timeout)` ile eleman queuedan alınır 

`xQueuePeek(handle, buffer, timeout)`front elemanı döndürür ancak queue'dan silmez.

## Queues and Timers Example 08

Exercise 08 -> kullanıcı UART'tan komut gönderir (Tera Term veya Putty ile).
                komuta göre LED ile ilgili işlemler yapabilir. farklı led'leri yakabilir
                farklı komutlar ile RTC ile ilgili ayarlar yapılır.

    5 farklı task oluşturulacak
        menu task   ->  
            - komutları alıp gerekli işlem akışını başlatacak task. menüyü bastırmak için gerekli komutları print task'a gönderecek.
            - bu mesajlar yine bir queue içerisinde saklanacak (print queue)
            - led kontrolü esnasında " Software Timers__ kullanılacak.
        
        led task    ->  girilen komuta göre gerekli LED işlemini yapacak
            - e1, e2, e3, e4 şeklinde komutlara göre odd/even gibi farklı led'ler kontrol edilecek.
            - 4 farklı software timer oluşturulacak ve 500ms aralıklarla LED'lerin hangileri açık hangileri kapalı karar verilecek. 
                - 
                ```cppcode
                //software timer handles 
                TimerHandle_t  handle_led_timer[4];

                //Create software timers for LED effects
	            for(int i = 0 ; i < 4 ; i++)
                {
		            handle_led_timer[i] = xTimerCreate("led_timer",pdMS_TO_TICKS(500), pdTRUE, (void*)(i+1),led_effect_callback);
                }

                ```
                - Callback fonksiyon oluştururken imzasına eklenen input argüman ile öğrenilebilir. input argüman handle olur. `pvTimerGetTimerID()` gibi bir fonksiyon ile.
                    ```cppcode
                    void led_effect_callback(TimerHandle_t xTimer)
                    {
                        int id;
                        id = ( uint32_t ) pvTimerGetTimerID( xTimer );

                        switch(id)
                        {
                        case 1 :
                            LED_effect1();
                            break;
                        case 2:
                            LED_effect2();
                            break;
                        case 3:
                            LED_effect3();
                            break;
                        case 4:
                            LED_effect4();
                        }
                    }
                    ```

        RTC task    ->  RTC modülü kontrol edecek.
                        time ve date set edilip istenirse menüye bastırılacak.
                        menüye bastırma işlemi ITM konsola yaptırılacak.
                            ITM konsol için de bir software timer oluşturulur.
                            1 saniyelik timer oluşturulur ve periyodik olarak her 1 saniyede ITM'den current time and date bastırılır.

        print task  ->  UART peripheral'ını kontrol edecek Task. Diğer Task'lar bir Queue'ya mesajlarını koyacak.
                        bu task bu Queue'dan alıp karakterleri bastıracak (UART ISR -> Enqueue to Queue)
                        
        command handler task -> UART_ISR -> notification -> Command handling task
            :: notify wait ile uarttan komutların işlenmesi bilgisini bekleyecek.
            :: gelen dataya göre ne işlem yapılacaksa bu task'ları notify edecek
            :: application bir çeşit menü olacağından hangi state'de olduğunu tutacak şekilde algoritmamızı oluşturmamız gerekli.
            :: bir helper ile gelen komutu anlamdırırız. basit bir switch case o anki state'de ne yapacağımıza karar veririz.
            :: queue'daki eleman sayısını "uxQueueMessagesWaiting(handle)" ile öğrenebiliriz. boş ise 0 döner.
            :: queue'daki elemanları "xQueueReceive(handle, data, timeout)" ile alırız. successful olduğunda true döner. data içerisine karakterleri koyarız. bu data'nın formatı oluşturacağımız bir struct ile tutabiliriz ("command_t").
    
    2 farklı Queue olacak
        1- input data queue
            ```cppcode
                q_data = xQueueCreate(10, sizeof(char)); // total consumed memory 10 bytes
            ```
        2- print queue
            ```cppcode
                // enqueue pointer to string/message
                // total consumed memory 10 bytes
                q_print = xQueueCreate(10, sizeof(size_t));
            ```
## LED Configuration

GPIO pin'leri ile LED'leri bir önceki uygulamalarda yaptığımız gibi Cube IDE Device Configuration Tool yardımıyla yaparız.

## UART Configuration

USART2 peripheral'ı bu amaç için default ayarlar ile konfigüre edeceğiz. NVIC altında "USART2 Global Interrupt" enable edilir. 
"Whenever a data is received from the user, the USART2 interrupt will trigger in the application and the USART2 ISR runs and it captures the data send by the user." Generate IRQ Handler seçeneği seçilir.
- UART interrupt modda byte-by-byte alacak şekilde konfigüre edilir
- UART callback implement edilir (HAL kütüphanesi tarafından otomatik çağırılırbir byte alınınca)
    - callback function ismi `HAL_UART_RxCpltCallback()` olmalıdır
    - gelen byte input data queue ya eklenir
    - '\n' gelirseartık komut bitmiş demektir ve handling task'a notification gönderir.
    - callback implemente ederken şunlara dikkat etmeliyiz
        - Queue boş olup olmadığı kontrol edilmelidir (@ref `xQueueIsQueueFullFromISR()`). eğer boş ise queue ya eleman eklenir (@ref `xQueueSendFromISR()`)
        - eğer receive karakter '\n' ise artık queuedan elemanlar command handling task'ın işlenmesi üzere notification gönderilir. aynı queue'ya baktıkları için data'yı göndermeye gerek kalmayacaktır. Ancak notification için daha önce öğrendiğimiz API'yi kullanırız (@ref `xTaskNotifyFromISR()`)
        - UART ı tekrar enable etmeliyiz.

- **Not:** UART'tan receive başlatabilmek için HAL fonksiyonu çağırılmalıdır (@ref `HAL_UART_Receive_IT()` interrupt için kullanılır. poll için farklı fonksyionu vardır.) uart ı enable edecek gerekli low-level işlemler yapılır register seviyesinde
- `UART_HandleTypeDef huart2;` şeklinde UART handle tanımlamamızı yapabiliriz.


## RTC Configuration

Timer sekmesi altında RTC konfigüre edilir. Activate clock source yapılır. Saat formatı seçilir.
SoftwareTimer kullanacağımız için, FreeRTOSConfig.h içerisinde ilgili 'configUSE_TIMERS' 1 yapılır 
- `RTC_HandleTypeDef hrtc;` şeklinde RTC handle tanımlamamızı yapabiliriz.
- Timer configure ederken `RTC_TimeTypeDef` kullanırız. ssaat, dakika , format vb field'lar mevcut.
- `HAL_RTC_SetTime(handle, config, format)` ile Time set edebiliriz. HAL içerisinde buna benzer Get ve Set fonksiyonları mevcut.


# Software Timers

bir LED'i 500ms aralıklarla toggle edeceğini düşünelim. Bunu yapmak üzere iki çeşit timers kullanılabilir

- **Hardware Timers:** MCU peripheral'larından TIMER kullanılır. freeRTOS API'ları kullanılmaz. kendi timer fonksiyonumuzun yazılması gerekir. periyot, irq vb konfigüre edilir. Micro/Nano seviyesinde resolution'a sahip olabiliriz. High Resolution Timer/ High Precision Timer olarak adlandırılır bu yüksek resolution

- **Software Timers:** FreeRTOS kernel'i tarafından yönetilir. FreeRTOS API'leri kullanılır. Resolution RTOS_TICK_RATE_HZ ile belirlenir. dolayısıyla sysTickTimer a da bağlıdır. `xTimerCreate/Start/Stop()` vb şeklinde API'lar mevcuttur.
    - `xTimerCreate(...)` ile timer create edilir. timer başlanmaz. yalnızca timer konfigürasyon için gerekli bilgiler verilir.
        - periyot belirtilir. 500ms dolunca callback çağırılır.
        - one shot olarak (tek sefer callback çağırlır) ve periodic olarak kullanılabilir
        - her Timer unique ID'ye sahiptir. callback içerisinde bu ID'ye göre işlem yapılabilri
        - handle ile tüm bu bilgilere erişilebilir.
    - `XTimerStart(handle, block_time)` ile timer başlatılabilir.
        - bu çağrı ile de freeRTOS kendi içerisinde queue kullanarak timer'lar queue ya eklenebilir. çouğ xTimerAAA API'si bu queue ya bir command olarak eklenir. source kodlar incelendiğinde bunlar görülebilir.