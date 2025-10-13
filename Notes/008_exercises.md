Exercise 02

3 task, 3 farklı LED2'i kontrol edecek şekilde bir uygulama geliştirilecek.

Öncesinde birkaç işlem yapıp projeler için daha generic bir altyapı oluşturmak istiyoruz. 

- "common" dosyası oluşturup freeRTOS ve Segger ile ilgili dosyaları bunun içerisine koyabiliriz. sonrasında projelere bu dosyayı link'leyerek kopyalamadan kullanabiliriz. bu durumda "exclude from source" seçeneğini proje settings den un-check yapmamız gerekir.

- "include path settings" ayarlarını bir kere yapıp export edebilir ve sonrasında diğer projelerde bunu import ederek kullanabiliriz. her proje için tek tek yapmak zorunda kalmayız.

- LED'ler için GPIO configure gereklidir. (MX_GPIO_Init ile yapılır. default initialize edildiği için otomatik olarak main.c dosyasına eklenir.)

- SysTickTimer için project settings -> SYS -> Timebase Source değiştirilip TIMx (systick'den farklı bir timer seçilir TIM6 gibi)

NVIC priortiy group sekmesinden -> 4-bit preemption ... seçilir
NVIC -> disable handlers for pendsv, svc, systicktimer,

Exercise 03 

yine 3 task ile Led yakma işlemini, HAL_delay verine vTaskDelay(pdMS_TO_TICK(...)) ile yapacağız.

Exercise 04

bu sefer delay fonksyionu yerine delayUntil kullanılacak

Exercise 05

daha önce hem task notification hem de task delete görmüştük. bu sefer bu ikisini birleştireceğiz.
bir butona basılarak bir task'a notification gönderilecek ve task bu notification sonrası kendisini delete edecek. (Task-to-Task communicarion)
button'a basılma işlemini de yine bir task içerisinde yapacağız. en yüksek önceliğe sahip olacak. Button işlemleri ise şu şekilde, butona basılmadığında low, basıldığında high oalrak ölçülmektedir. Low-to-High ve High-to-Low arası süre ne kadar basılı kaldığını ölçebiliriz.
- task'lar sırası ile silinir. silinecek task için next_task_handle global değişken kullanılmıştır. ilk silinecek "next_task_handle = ledg_task_handle;" şeklinde tanımlana green led handler'dır.
- her butona basıldığında notification üretilir. led'i yakıp söndüren task delete edilir. led'ler toggle etmeyi bırakır ve sadece yanık olarak kalır


Exercise 06

bir öncekine benzer işlemleri bu sefer Task-to-ISR arasında yapacağız.
bir butona basıldığında interrupt oluşacak ve ISR çalışacak.
3 task -> toggle 3 different LEDs (Task'lar process context de çalışır)
1 ISR -> button pressed, notifies toggle led task and task will delete itself (ISR interrupt context de çalışır)

- `xTaskNotify()` fonksiyonu artık ISR içinde kullanılamaz. bir önceki örnekte bunu kullanarak notify göndermiştik ancak artık freeRTOS'da ISR içinden de çağırılabilen özel API'ler çağıracağız. bunların sonunda "FromISR" isimlendirmesini görebiliriz.

- `xTaskNotifyWait()` kullanımında herhangi bir sorun bulunmuyor. bu durum yalnızca notification için değil queue vb konseptler için de geçerlidir (`xQueueSendFromISR()` gibi)

- ISR üretimi için, butona basıldığında, Buton=PA0 GPIO pin'ine bağlı olduğundan cube ide içerisinde GPIO içerisinde bu pini interrupt modunda seçmeliyiz. bu esnada ne zaman üreteceği (bizim senaryomuzda falling edge esnasında üretilmesi gerekiyor çünkü butona basıldığında pinin değerini low görürüz.)
- sonrasında NVIC içerisinde, "EXTI Line 0" interrupt'ı enable edilmelidir. bu interrupt için bir priority vermeliyiz ancak bunu verirken ISR içinde çağırılacak ISR'lar için olan threshold (bir önceki derslerde açıklamıştık) değerinden numeric olarak büyük değer vermeliyiz
- bu EXTI line 0 interrupt'ı için code generation'ı tick'lediğimizde IRQ handler'ı bizim için koda ekliyor olacak.
-   
    ```@cppcode/* EXTI interrupt init*/
    HAL_NVIC_SetPriority(EXTI0_IRQn, 6, 0);
    HAL_NVIC_EnableIRQ(EXTI0_IRQn);
    ```
- **not:** Handler içerisinde pending bit'i clear etmeyi unutmamalıyız...
- **güzel nokta:::** fark edeceksiniz ki hangi task'ın çalıştığını bir global değişkende tutuyoruz (next_task_handle). bu değişken artık ISR ile task'lar arasında ortak kullanılan kaynak durumuna gelmiştir, shared resource. bu nedenle bu değişken task içerisinde kullanılırken interrupt'ları disable ederek cirticals section içerisine alırız. bunu alternatif olarak semaphore/mutex benzeri yapılar ile de yapabiliriz.

    ```@cppcode
    static void led_red_handler(void* parameters)
    {
        BaseType_t  status;

        while(1)
        {

            HAL_GPIO_TogglePin(GPIOD, LED_RED_PIN);
            status = xTaskNotifyWait(0,0,NULL,pdMS_TO_TICKS(400));
            if(status == pdTRUE)
            {
                /**
                bu fonksiyon base priortiy değerini değiştirecek şekilde instruction kullanır. bu şu demektir, threshold u 5 (configMAX_SYSCALL_INTERRUPT_PRIORITY) olarak ayarladığımız max syscall
                interrupt'ının üstünde interruptları disable eder (5 ile 15 arası)
                aynı zamanda PendSV de disable olur çünkü onun değeri 15 ile en düşük priority e sahiptir.
                */
                portENTER_CRITICAL();

                next_task_handle = NULL;
                HAL_GPIO_WritePin(GPIOD, LED_RED_PIN,GPIO_PIN_SET);

                portEXIT_CRITICAL();
                vTaskDelete(NULL);
            }

        }

    }
    ```

- 