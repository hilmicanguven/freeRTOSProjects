# Idle Task

kernel tarafından (scheduler) otomatik olarak üretilen task'tır. en düşük önceliğe sahiptir. diğer uygulamaların çalışmasını etkilemez. oluşturulmasının amacı CPU'da en azından bir tane task'ın çalışması içindir.

bir başka önemli kullanımı, **delete edilen task'lara ait belleğin de-allocate edilmesi de yine idle task tarafından yapılır.**

idle task içerisinde CPU'yu düşük güç moduna geçirmek için bir fonksiyon bağlanabilir. bir çeşit callback bağlanarak farklı bir işlem yaptırılması da mümkündür.

# Timer Services Task

eğer software timer kullanılacak ise, `configUSE_TIMERS` flasg'i ile belirlenir, bu da scheduler tarafından kernel başladığında oluşturulur. `xTimerCreateTimerTask` ile oluşturulur.