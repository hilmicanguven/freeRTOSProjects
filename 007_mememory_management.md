# Memory Types

Genellikle MCU'larda RAM ve Flash olmak üzere 2 tip memory bulunur.

## RAM

- Global değişkenleri saklamakiçin kullanılır
- RAM içerisine kod yükleyebilir ve çalıştırabiliriz.
- Stack olarak kullanılmak üzere RAM'den bir bölge ayırabiliriz.
- Heap olarak kullanılmak üzere RAM'den bir bölge ayırabiliriz. Dynamic Memory Allıocation için kullanılır

## Flash

- Non-volatile memory'dir
- Application code'u tutabilir
- Constant değişkenler bu bellekte saklanabilir
- MCU'nun vector tablosu (exception ve interrupt'larını içinde barındırır) saklanabilir.

# Stack and Heap

RAM içerisinde heap ve stack olarak kullanılacak bölgeler belirlenir. SP register'ı stack başlangıcını gösterecek şekilde güncellenir. Bu pointer MSP'dir ve board reset atıldıktan sonra processor'un yaptığı ilk işlemdir. bu MSP değeri 0x0000_0000 adresinde bulunur. Heap ise başlıca malloc/free operasyonları için kullanılır. 

stack ve heap dışında kalan bölge ise, global data, attay, static değişkenler bulunur.

## Stack
- FILO şeklinde yönetilir.
- bir fonksiyon çağrısı yapıldığında, SP yer değiştirir. fonksiyona giden argümanlar stack'e eklenir. fonksiyon dönüşünde çalışılacak kod "return address" stack'e eklenir. fonksiyon içinde tanımlanan local değişkenler stack'te oluşturulur. fonksiyonun döneceği değer yine stack'de saklanır.
- bir fonksiyon çağrısı yapıldığında
    - r0,r1,r2 -> register'lar fonksiyon input argümanlarını saklar
    - return address push edilir
    - fonk içinde oluşturulan local değişkenler push edilir
    - fonk return ederken R0 içinde return value saklanır

## Heap
- heap'e yapılan erişimler rastgele olur. stack'teki gibi bir pointer bulunmaz ki heap'e erişebilelim. heap "dynamic memory allocation" bir bellek bölgesi olarak düşünelim. bu bölgenin yönetimi ise kullandığımız runtime koda göre değişir.
    - örneğin, C dilinde "malloc" bunu yaparken, C++ dilinde "new" keyword'u bunu yapar.
    - kendi OS'imizi oluşturduğumuzda bunu kendimiz yere getirebiliriz. bu kullanılan MCU ve memoryprotection unit'e bağlıdır.
    - ayrıca heap yönetimide, heap için ayrlan bölgenin iyi yönetilmesi, minumum kaç resolution'da bellek tahsisine izin verilecek karar verilmelidir. bu genelde "page" olarak adlandırılabilir.

# freeRTOS Heap Yönetimi

### Heap
freeRTOS'da heap boyutu default olarak Kernel tarafından belirlenir (configTOTAL_HEAP_SIZE) ancak istenirse configAPPLICATION_ALLOCATED_HEAP = 1 yapılarak application tarafından da belirlebilir

- xTaskCreate() fonksiyonu ile task oluşturunca heap'de TCB-1 ve STACK-1 oluşturulur. 
- Semaphore, Queue oluşturulunca yine Heap'de boş bir yere koyulur.

freeRTOS altında 5 tane farklı heap implementasyonu bulunur. 6.yı da kullanıcı kendisi ekleyebilir.

- heap_1.c : `pvPortMalloc()`
- heap_2.c : `pvPortMalloc()` , `vPortFree()`
- ...
- your_own_heap.c

# freeRTOS Syncronization & Mutex Servisleri

# Syncronization

birden fazla işlem yapan task'ın, birbirleri ile uyum halinde çalışmasıdır. genellikle "producer" ve "consumer" olarak adlandırılan iki task birbirlerini bekleyebilir ve sinyal gönderebilir. bu bekleme işlemini CPU'yu meşgul etmeden yapması gerekir. benzer şekilde ISR ile Task arasında da senkronizasyon sağlanabilir.

Bu signaling işlemi
- events
- semaphores
- queues and message queues
- pipes
- mailboxes
- signals (UNIX like signals)
- Mutex

# Mutual Exclusion

shared resource'a aynı anda yalnızca bir task'ın erişmesi demektir. global bir değişken shared resource'a bir örnektir. buna yapılacak erişimin dikkatli yapılması gereklidir. bu nedenle synchronization nesnelerinin kullanılarak erişim güvenli hale getirilmesi ve birden fazla task'ın erişmesinin engellmesi gereklidir.
