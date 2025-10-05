/*

This repository created by following online course "Mastering RTOS: Hands on FreeRTOS and STM32Fx with Debugging"
Link -> https://stm.udemy.com/course/mastering-rtos-hands-on-with-freertos-arduino-and-stm32fx/

Projelerde 
Board: STM32F407x DISCOVERY 
OS: freeRTOS is ported
IDE: STM32CUBEIDE


RTOS vs GPOS

    Determinism 

    | Özellik        | RTOS                          | GPOS                                      |
    | -------------- | ----------------------------- | ----------------------------------------- |
    | **Zamanlama**  | Gerçek zamanlı, deterministik | Zamanlama belirsiz, öncelik garantisi yok |
    | **Gecikmeler** | Çok düşük ve öngörülebilir    | Değişken ve daha yüksek olabilir          |


    Scheduling:

    | Özellik              | RTOS                                   | GPOS                             |
    | -------------------- | -------------------------------------- | -------------------------------- |
    | Scheduler tipi   | Öncelik tabanlı, genellikle preemptive | Zaman paylaşımı (*time-sharing*) |
    | İşlem önceliği   | Kesin olarak kontrol edilir            | Sistem tarafından yönetilir      |

    Priority Inversion

    RTOS'larda, scheduling genellikle kullanılan  yöntem priority based olur.
    yani yüskek öncelikle task her zaman daha önce çalışmalıdır. ve bu durumda düşük öncelikli task çalışması yarıda kesilebilir.
    Eğer ki High Priority Task (HPT), Low Priority Task'ın (LPT) çalışmasını beklediği durumda sonsuza kadar bekleyebilir
    bu durum genellikle ortak bir kaynağa erişim esnasında olur.
    çünkü LPT ye HPT'den dolayı sıra gelmez. bu durumda LPT'nin önceliğinin geçici süreliğine artırılması gerekir.
    buna priority inversion denir.


Ortam ve Program Kurulumları

IDE 
    IDE olarak STM32CUBE IDE kullanılacak. kurulumları burada anlatacak değiliz diye düşünüyorum :)

Board
    STM32 DISCOVERY board kullanacağız. 
    ARM Cortex M4 işlemci mevcut, FPU(Floating Point Unit) mevcut
    8MHz crystal oscillator mevcut
    On board programmer ve debugger var.
    Dökümanlar eklenmiştir
        MCU ile ilgili dökümanlar ->
            Reference Manuel*** oldukça önemlidir.
            Datasheet
        Board özelinde dökümanlar ->
            Schematic, data brief vb

FreeRTOS
    freeRTOS kodlarını workspace/proje ye port etmeliyiz.
    Kaynak kodlarını kendi sitesinde indirip kendi projemiz altına kopyalamak bir çözüm.            
    Ancak burada bir genelleme yapmayalım. hangi gün çalışılıyorsa o günün şartlarında "how to import freertos into my project" yazarak araştırılması tavsiye edilir.
    https://github.com/FreeRTOS/FreeRTOS-Kernel

    Kursta freeRTOS tabanlı bir proje için şu adımlar yapıldı
        - boş bir stm32 projesi oluşturulur.
        - freeRTOS kernel, proje içerisine eklenir. manuel şekilde yapılır. alternatif olarak -> "STM32 device configuration tool"
            (CMSIS RTOS -> generic ARM cortex m serisi için oluşturulan software layer) ancak şu anlık kullanılmayacak
            (CMSIS CORE -> arm cortex m4 peripheral kullanımı için kullanılacak)
            GCC ve Memory Management ile ilgili freeRTOS dosyaları proje altına kopyalanır (Third Party)
        - proje ayarları kısmında "include path" ayarları
        - freeRTOSConfig.h
            bu dosya önemli, freeRTOS konfigürasyonu için kullanılıyor Ancak indirilen dosyalar arasında yok. manuel eklenmesi gerekli
            fix bug for multiple definitions
    **not: STM32 CUBE IDE içerisinde doğrudan GUI'den de projeye port edilebilir
        middleware and software packages altından eklenebilir.
        çeşitli config ayarları da buradan yapılabilir.

Timebase Seçimi
    RTOS çalışması için gerekli ticking (periyodik saat sinyalidir, systick interrupt tarafından oluşturulur)
    systick, scheduler çalışmasını belirler. delay/sleep gibi fonksiyonlar bu sayede yürütülür
    hangi sıklıkla tick oluşacağı için bir clock kaynağı olmalıdır
    freeRTOS, arm cortex m işlemcisnin internal timer'ını kullanır
    STM32 cube HAL da bunu kullanır. ancak aynı olması durumunda conflict çıkabilir
    STM32 cube hal için genellikle farklı bir source seçilmesi tavsiye edilir
        STM32cube içerisinde "System Core" -> "SYS" için farklı bir timer seçilebilir

*/
