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
bir butona basılarak bir task'a notification gönderilecek ve task bu notification sonrası kendisini delete edecek.
button'a basılma işlemini de yine bir task içerisinde yapacağız. en yüksek önceliğe sahip olacak. Button işlemleri ise şu şekilde, butona basılmadığında low, basıldığında high oalrak ölçülmektedir. Low-to-High ve High-to-Low arası süre ne kadar basılı kaldığını ölçebiliriz.
- task'lar sırası ile silinir. silinecek task için next_task_handle global değişken kullanılmıştır. ilk silinecek "next_task_handle = ledg_task_handle;" şeklinde tanımlana green led handler'dır.
- her butona basıldığında notification üretilir. led'i yakıp söndüren task delete edilir. led'ler toggle etmeyi bırakır ve sadece yanık olarak kalır

