# 【实现】初始化中断控制器

80386把中断号0～31分配给陷阱、故障和非屏蔽中断，而把32～47之间的中断号分配给可屏蔽中断。可屏蔽中断的中断号是通过对中断控制器的编程来设置的。下面描述了对8259A中断控制器初始化过程。

8259A通过两个I/O地址来进行中断相关的数据传送，对于单个的8259A或者是两级级联中的主8259A而言，这两个I/O地址是0x20和0x21。对于两级级联的从8259A而言，这两个I/O地址是0xA0和0xA1。8259A有两种编程方式，一是初始化方式，二是工作方式。在操作系统启动时，需要对8959A做一些初始化工作，即实现8259A的初始化方式编程。8259A中的四个中断命令字（ICW）寄存器用来完成初始化编程，其含义如下：

* ICW1：初始化命令字。
* ICW2：中断向量寄存器，初始化时写入高五位作为中断向量的高五位，然后在中断响应时由8259根据中断源（哪个管脚）自动填入形成完整的8位中断向量（或叫中断类型号）。
* ICW3： 8259的级联命令字，用来区分主片和从片。
* ICW4：指定中断嵌套方式、数据缓冲选择、中断结束方式和CPU类型。

8259A初始化的过程就是写入相关的命令字，8259A内部储存这些命令字，以控制8259A工作。有关的硬件可看附录补充资料。这里只把ucore对8259A的初始化过程（在picirq.c中的pic_init函数实现）描述一下:

	//此时系统尚未初始化完毕，故屏蔽主从8259A的所有中断

	outb(IO_PIC1 + 1, 0xFF);
	outb(IO_PIC2 + 1, 0xFF);
    
	// 设置主8259A的ICW1，给ICW1写入0x11，0x11表示（1）外部中断请求信号为上升沿触发有效，（2）系统中有多片8295A级联，（3）还表示要向ICW4送数据

    // ICW1设置格式为:  0001g0hi  
    //    g:  0 = edge triggering, 1 = level triggering  
    //    h:  0 = cascaded PICs, 1 = master only  
    //    i:  0 = no ICW4, 1 = ICW4 required  

	outb(IO_PIC1, 0x11);

	// 设置主8259A的ICW2:  给ICW2写入0x20，设置中断向量偏移值为0x20，即把主8259A的IRQ0-7映射到向量0x20-0x27

	outb(IO_PIC1 + 1, IRQ_OFFSET);

	// 设置主8259A的ICW3:  ICW3是8259A的级联命令字，给ICW3写入0x4，0x4表示此主中断控制器的第2个IR线（从0开始计数）连接从中断控制器。

	outb(IO_PIC1 + 1, 1 << IRQ_SLAVE);
    
	//设置主8259A的ICW4：给ICW4写入0x3，0x3表示采用自动EOI方式，即在中断响应时，在8259A送出中断矢量后，自动将ISR相应位复位；并且采用一般嵌套方式，即当某个中断正在服务时，本级中断及更低级的中断都被屏蔽，只有更高的中断才能响应。

	// ICW4设置格式为:  000nbmap
	//    n:  1 = special fully nested mode
	//    b:  1 = buffered mode
	//    m:  0 = slave PIC, 1 = master PIC
	//      (ignored when b is 0, as the master/slave role
	//      can be hardwired).
	//    a:  1 = Automatic EOI mode
	//    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
	outb(IO_PIC1 + 1, 0x3);

	//设置从8259A的ICW1：含义同上

	outb(IO_PIC2, 0x11);	// ICW1
    
	//设置从8259A的ICW2：给ICW2写入0x28，设置从8259A的中断向量偏移值为0x28

	outb(IO_PIC2 + 1, IRQ_OFFSET + 8);	// ICW2
    
	//0x2表示此从中断控制器链接主中断控制器的第2个IR线

	outb(IO_PIC2 + 1, IRQ_SLAVE);	// ICW3
    
	//设置主8259A的ICW4：含义同上

	outb(IO_PIC2 + 1, 0x3);	// ICW4

	//设置主从8259A的OCW3：即设置特定屏蔽位（值和英文解释不一致），允许中断嵌套；不查询；将读入其中断请求寄存器IRR的内容

	// OCW3设置格式为:  0ef01prs
	//   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
	//    p:  0 = no polling, 1 = polling mode
	//   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
	outb(IO_PIC1, 0x68);	// clear specific mask
	outb(IO_PIC1, 0x0a);	// read IRR by default

	outb(IO_PIC2, 0x68);	// OCW3
	outb(IO_PIC2, 0x0a);	// OCW3
    
	//初始化完毕，使能主从8259A的所有中断

	if (irq_mask != 0xFFFF) {
		pic_setmask(irq_mask);
	}