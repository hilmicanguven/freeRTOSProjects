# Queues

Bir çeşit data structure'dır aslında. Belirli bir boyutta veri depolayabilir. FIFO şeklinde çalışan bir buffer'dır. (Klasik Head-Tail ve Enqueue-Dequeue)

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
    
    2 farklı Queue olacak
        1- input data queue
            ```
                q_data = xQueueCreate(10, sizeof(char)); // total consumed memory 10 bytes
            ```
        2- print queue
            ```
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
    - callback function ismi 'HAL_UART_RxCpltCallback' olmalıdır
    - gelen byte input data queue ya eklenir
    - '\n' gelirseartık komut bitmiş demektir ve handling task'a notification gönderir.


## RTC Configuration

Timer sekmesi altında RTC konfigüre edilir. Activate clock source yapılır. Saat formatı seçilir.
SoftwareTimer kullanacağımız için, FreeRTOSConfig.h içerisinde ilgili 'configUSE_TIMERS' 1 yapılır 