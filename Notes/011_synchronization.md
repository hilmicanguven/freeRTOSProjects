# Synchronization ve Mutual Exclusion

Synchronization, Bir olayın oluşması/gerçeleşmesi için belirli bir referns doğrultusunda el sıkışmak diyebiliriz. RTOS özelinde, Task'lar arası haberleşme ve senkronizasyonu sağlamak için bazı Kernel nesneleri bulunur. Genellikle "producer" ve "consumer" olarak adlandırılan ve birbirlerine ihtiyaç duyan task'lar arasında bu nesneleri kullanırız.

- Semaphore nesneleri ile bir çeşit sinyal mekanizması ile bekleyen Task'a bir haber göndeririz. Kaldığı yerden devam edebilsin diye. Senkronizasyonu sağlamış oluruz.
- Mutual Exclusion ise, aynı anda bir kaynağa tek bir Task'ın erişebilmesini garanti etmeye yarayan biraz daha farklı bir konsepttir. bu korumaya alınan bölgeye "critical section" ismi verilir. Genellike "Mutex" nesneleri bu amaç için kullanılır. Semaphore ile yapılabilir ancak bazı tasarım problemlerine sebep olabilir.

# Semaphore

Semaphore oluştururken unique id, SCB (semaphore control block) ve semaphore'un kaç tane Key/Token'e sahip olduğu bilgisi verilir. Key/Token sayısı kaç tane kaynak olduğunu gösterir.Birden fazla consumer'ın kullanacağı bir kaynak için sempahore nesnesinde bu Key değeri 1 den fazladır. Bir task sempahore'u beklediği zaman blocked state'e geçer. FIFO veya Priority-Based şeklinde bekleyen task'lar waiting list'e eklenir. İki çeşit Semaphore bulunur.

1. Binary Semaphore

Key sayısı 0 veya 1 (Available) değerini alır. Synchronization veya Mutual Exclusion amacıyla kullanılır.
Senkronizasyonu sağlamak için
- bir task producer Task-1 olsun. semaphore'u elinde tutar ve başkası tarafından istenen data available ise değerini 1 artırır.
- farklı bir task consumer Task-2 olsun. bu da Task-1'in elinde tuttuğu data'ya ihtiyaç duyar. bunun için sempahore'dan bir Token (bu durumda zaten yalnızca bir tane var) almaya çalışır. eğer alabilirse değerini bir azaltıp 0 yapar. eğer semaphore alamazsa (değeri 0 ise) Task-2 blocked state'e geçer. Bu durum Task-1'in semaphore'un değerini artırına kadar (give, post vb isimlendirme kullanılır) bekler.

## Semaphore in ISR (Interrupt - to - Task Syncronization)

bir önceki durumda task-to-task yapmıştık. ISR içerisinde fazla işlem yapmak istemeyince genelde bir helper task oluştururuz ve bu helper'ı ISR içinde veririz. (signal-post-give artık ne isim verirseniz :D ) bu durumda semaphore'u ilk oluşturduğumuzda un-available olarak işaretleriz.

- **Not:** ISR içinde `xSemaphoreGiveFromISR()` fonksiyonu kullanılmalıdır.

ISR ve Task arasında yaşanan olaylar şu şekilde ilerler..
- Eğer ISR çalışıp helper task'a semaphore'u verdiğinde helper çalışmaya başlar. Eğer henüz helper task çalışmasını bitirmeden ikinci bir ISR gelirse helper **preempt** edilir. ISR tekrar sempahore'u post etmeye çalışır ve değerini 1 artırır. Eğer Task ilk semaphore'u aldıktan sonra ISR çalışırsa, Task toplamda 2 kere çalışır. Ancak bu esnada 20 kez ISR çalışsa sempahore değeri en fazla 1 olacağı için değeri artmayacaktır. O nedenle en fazla 1 veya 2 kere çalışacaktır. Diğer ISR'ları kaçıracağız yani. (Events Latching olarak adlandırılır bu işlem -> Task'ın ard arda gelen ISR'lara göre birden fazla çalışabilmesi)

2. Counting Semaphore

Key sayısı 1'den fazladır. Her bir task Key'i aldığında bu değer 1 azalır. Bıraktığında 1 artar. Bu tip amacın amacı "resource management" içindir.

Event Latching konusunda kullanımı daha mantıklı olan Counting Semaphore kullanmaktır. ISR içerisinde semaphore değeri artıldığını düşünelim. Task, key'i alsın veya almasın semaphore değeri 1-2-3-4 şeklinde artabilecektir.

**Not:** `xSemaphoreCreateCounting` arayüzü ile counting semaphore oluştururuz.

# Exercise

`xSemaphoreHandle xWork` şeklinde bir handle oluşturup, `vSemaphoreCreateBinary(xWork)` ile sempahore oluşturabiliriz. `xSemaphoreGive (xWork)` ile semaphore'un ilk durumda available olduğunu belirtebiliriz. çünkü yaratılırken semaphore empty olarak default edilir. Ya da Producer task içerisinde ne zaman data hazırsa yapabiliriz. `taskYIELD()` kullanarak hemen sonrasında diğer task'lara geçiş yapması için CPU'yu salar.

Consumer Task ise, `xSemaphoreTake( xWork, 0)` ile semaphore'u bekler. ikinci parametre ile ne kadar süre block state'de kalacağı belirtilebilir

**Not:** `xSemaphoreCreateCounting` arayüzü ile counting semaphore oluştururuz.

# Mutual Exclusion

## Mutual Exclusion using Binary Semaphore

Serial/UART peripheral ile konsola mesaj bastırmaya çalışan 2 task olsun. Eğer birbirleri ile bunu bir düzene oturtmaz isek konsolda kendi mesajlarımız yerine karışık şekilde bastırılan karakterler göreceğiz. Çünkü scheduler tarafından task'lar arka arkaya çalıştırılacak ancak print işleminin bitip bitmediğine bakılmayacaktır.

Bunu çözmek için print mesajının konsola bastırıldığı kısım, critical section'a alınarak, bu işlemin başında semaphore'u alıp UART Data Register boşaldığında yani yazma işlemi bittiğinde Semaphore Give yapılır (değeri 1 artar) ve farklı bir task artık bunu alabilir.

## Advantages Mutex over Semaphore

Todo

# Priority Inversion / Inheritance

Todo

# Crude (Ham/Kaba) Way to Protect Critical Section

`taskENTER_CRITICAL()` ve `taskEXIT_CRITICAL()` api'lerini kullanarak interrupt'ları disable ve re-enable ederek istediğimiz alanı koruyabiliriz. interrupt'lar disable olduğu esnada pre-emption gerçekleşemeyeceğinden işlem yarıda kalmayacaktır.