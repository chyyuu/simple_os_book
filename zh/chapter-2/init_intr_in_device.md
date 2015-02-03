# 【实现】外设的相关中断初始化

串口的初始化函数serial_init（位于/kern/driver/console.c）中涉及中断初始化工作的很简单：

    ......
    // 使能串口1接收字符后产生中断
        outb(COM1 + COM_IER, COM_IER_RDI);
    ......
    // 通过中断控制器使能串口1中断
    pic_enable(IRQ_COM1);
  
键盘的初始化函数kbd_init（位于kern/driver/console.c中）完成了对键盘的中断初始化工作，具体操作更加简单：

    ......
    // 通过中断控制器使能键盘输入中断
    pic_enable(IRQ_KBD);
  
时钟是一种有着特殊作用的外设，其作用并不仅仅是计时。在后续章节中将讲到，正是由于有了规律的时钟中断，才使得无论当前CPU运行在哪里，操作系统都可以在预先确定的时间点上获得CPU控制权。这样当一个应用程序运行了一定时间后，操作系统会通过时钟中断获得CPU控制权，并可把CPU资源让给更需要CPU的其他应用程序。时钟的初始化函数clock_init（位于kern/driver/clock.c中）完成了对时钟控制器8253的初始化：

        ......
    //设置时钟每秒中断100次
        outb(IO_TIMER1, TIMER_DIV(100) % 256);
        outb(IO_TIMER1, TIMER_DIV(100) / 256);
    // 通过中断控制器使能时钟中断
        pic_enable(IRQ_TIMER);