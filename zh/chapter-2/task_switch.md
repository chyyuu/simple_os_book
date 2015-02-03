# 【背景】80386的任务切换

`任务`是80386硬件描述中的一个名词，在这里我们可以简单地把运行在内核态的ucore成为一个任务，把运行在用户态的应用称为另外一任务。任务寄存器(Task Register，简称TR) 储存了一个16位的选择子(对软件可见)，用来索引全局描述符表(GDT)中的一项。TR对应的描述符描述的一个任务状态段(TSS:Task Status Segment)。

TSS 任务状态段(Task State Segment，简称TSS)。任务状态段（TSS）是位于GDT中的一个系统段描述符。任务状态段是做什么的呢？任务状态段就是内存中的一个数据结构。这个结构中保存着和任务相关的信息。当发生任务切换的时候会把当前任务用到的寄存器内容(CS/ EIP/ DS/SS/EFLAGS...)等保存在TSS中以便任务切换回来时候继续使用。ucore根据80386硬件手册建立的TSS数据结构如下所示：

    struct taskstate {                                                                                 
        uint32_t ts_link;		// 链接字段
        uintptr_t ts_esp0;		// 0级栈指针
        uint16_t ts_ss0;		// 0级栈段寄存器
        uint16_t ts_padding1;
        uintptr_t ts_esp1;
        uint16_t ts_ss1;
        uint16_t ts_padding2;
        uintptr_t ts_esp2;
        uint16_t ts_ss2;
        uint16_t ts_padding3;
        physaddr_t ts_cr3;		// 页目录基址寄存器
        uintptr_t ts_eip;		// 切换的上次EIP
        uint32_t ts_eflags;
        uint32_t ts_eax;		// 保存的通用寄存器eax
        uint32_t ts_ecx;
        uint32_t ts_edx;
        uint32_t ts_ebx;
        uintptr_t ts_esp;
        uintptr_t ts_ebp;
        uint32_t ts_esi;
        uint32_t ts_edi;
        uint16_t ts_es;			// 保存的段寄存器
        uint16_t ts_padding4;
        uint16_t ts_cs;
        uint16_t ts_padding5;
        uint16_t ts_ss;
        uint16_t ts_padding6;
        uint16_t ts_ds;
        uint16_t ts_padding7;
        uint16_t ts_fs;
        uint16_t ts_padding8;
        uint16_t ts_gs;
        uint16_t ts_padding9;
        uint16_t ts_ldt;
        uint16_t ts_padding10;
        uint16_t ts_t;			// 调试陷阱标志(只用位0)
        uint16_t ts_iomb;		// i/o map 基地址
    };

从上图中可以 ，TSS的基本格式由104字节组成。这104字节的基本格式是不可改变的，但在此之外系统软件还可定义若干附加信息。基本的104字节可分为链接字段区域、内层栈指针区域、地址映射寄存器区域、寄存器保存区域和其它字段等五个区域。

其中比较重要的是内层栈指针区域，为了有效地实现保护，同一个任务在不同的特权级下使用不同的栈。例如，当从外层特权级3变换到内层特权级0时，任务使用的栈也同时从3级变换到0级栈；当从内层特权级0变换到外层特权级3时，任务使用的栈也同时从0级栈变换到3级栈。所以ucore使用的是0级栈，用户态应用使用的是3级栈。
TSS的内层栈指针区域中有三个栈指针，它们都是48位的全指针(16位的选择子和32位的偏移)，分别指向0级、1级和2级栈的栈顶，依次存放在TSS中偏移为4、12及20开始的位置。当发生从3级向0级转移时，把0级栈指针装入0级的SS及ESP寄存器以变换到0级栈。没有指向3级栈的指针，因为3级是最外层，所以任何一个向内层的转移都不可能转移到3级。但是，当特权级由0级向3级变换时，并不把0级栈的指针保存到TSS的栈指针区域。这表明向3级向0级转移时，总是把0级栈认为是一个空栈。

当发生任务切换时，80386中各寄存器的当前值被自动保存到TR所指定的TSS中，然后下一任务的TSS的选择子被装入TR；最后，从TR所指定的TSS中取出各寄存器的值送到处理器的各寄存器中。由此可见，通过在TSS中保存任务现场各寄存器状态的完整映象，实现任务的切换。