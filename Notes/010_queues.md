# Queues

Bir çeşit data structure'dır aslında. Belirli bir boyutta veri depolayabilir. FIFO şeklinde çalışan bir buffer'dır. (Klasik Head-Tail ve Enqueue-Dequeue)

Queue oluşturmak için aşağıdaki şekilde Queue handle tanımlamamızı yaparız. İleride göreceğimiz API'leri bu handle'lar aracılığı ile çağıracağız.
```cppcode
QueueHandle_t q_data;
QueueHandle_t q_print;
```

`xQueueCreate(...)` ile queue oluşturabilir. Return tipi handle'dır. kaç item tutacağı ve her birinin boyutunu input parametre olarak veririz.

`xQueueSendToFront(handle, item, timeout)` ile queue ya eleman ekleyebiliriz. timeout ise queue'nun full olması durumunda beklenecek maximum tick süresidir. tabi diğer bir seçenek boşalana kadar beklemektir, 0 verilerek. "port_MAX_DELAY" ile sonsuza kadar bekler. `xQueueSendToFront` ile de queue nun sonuna ekleyebiliriz. 

`xQueueReceive(handle, buffer, timeout)` ile eleman queuedan alınır 

`xQueuePeek(handle, buffer, timeout)`front elemanı döndürür ancak queue'dan silmez.

## Queues and Timers Example 08

Exercise 08 -> kullanıcı UART'tan komut gönderir (Tera Term veya Putty ile).
                komuta göre LED ile ilgili işlemler yapabilir. farklı led'leri yakabilir
                farklı komutlar ile RTC ile ilgili ayarlar yapılır.

    5 farklı task oluşturulacak
        menu task   ->  komutları alıp gerekli işlem akışını başlatacak task. menüyü bastıracak.
        led task    ->  girilen komuta göre gerekli LED işlemini yapacak
        RTC task    ->  RTC modülü kontrol edecek

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
- `RTC_HandleTypeDef hrtc;` şeklinde UART handle tanımlamamızı yapabiliriz.