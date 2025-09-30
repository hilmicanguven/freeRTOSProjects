freeRTOS içerisinde neler olup bittiğini daha iyi anlamak için bazı "trace tool" mevcuttur.
1. SEGGER SystemView Software -> host bilgisayarda kurulur
2. SEGGER SystemView Target Source Files -> target embedded board içerisinde bulunan ve target içinde olan event'leri bilgisayara gönderen yazılımlardır.
    - Proje altında "third part" dosyalar altına eklenebilir
    - freeRTOS source dosyaları içerisinde bazı patch işlemi uygulmaka gerekir. (apply patch -> select segger patch file)
    - SEGGER_SYSVIEW_FreeRTOS.h, freeRTOS_Config.h içerisinde include edilir ve bazı macro ayarları yapılır
    - MCU ve project specific settings

# Segger SystemView

    target board da çalıştırdığımız kodun davranışı izlemek için kullanılan bir araçtır.
    freeRTOS ya da farklı bir OS koşması zorunlu değildir.
    Burada freeRTOS özelinde neleri analiz edeceğimizi açıklayalım
        
        - CPU'da çalışan task ve çalışma sürelerini görebiliriz, cpu load
        - ISR giriş çıkış süreleri (systick interrupt zamanlamaları)
        - uygulamaların run-time davranışları ve task'lara ait bilgiler

# SystemView Visualization Modes

2 çeşit çalışma modu bulunur.

## Real Time Recording

    SEGGER J-Link ile RTT (Real Time Transfer) teknolojisi ile anlık-sürekli olarak data kayıt eder ve canlı olarak takip edilebilir.

    J-Link yerine ST-link kullanarak da bunu yapabiliriz. (j-link firmawre, board üzerindeki debug circuit içerisine yüklenmelidir.)

    Bunun için SystemViewAPI ve RTT API layer olarak eklenmelidir.
    Ayrıca RAM içerisinde bunun için gerekli buffer'lara yer ayrılmalıdır.

## Single-Shot Recording

    herhangi bir debugger'a ihtiyaç duyulmaz. application içerisinde manual olarak başlatılabilir.
    Yine benzer software layer'lar koda eklenir ve çıktı olarak .SVD uzantılı bir dosya oluşturur.