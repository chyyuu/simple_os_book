# 基于内核线程实现全局内存页替换机制

## 实验目标

到proj11为止，还没有能够在ucore中实现一个完整的内存页替换机制。但其实在lab2的proj8中，已经为ucore实现内存页替换机制提供了大量的支持，并在相关测试函数kern/mm/swap.c::check_swap中进行了检查。但这个检查只是说明了proj8提供了能够完成内存页替换机制的数据结构和函数支持，即已经一砖一瓦地完成了门窗、墙壁等建筑工作，还差把相关部件完整组织起来实现成一个完整的房子。proj11就是完成这最后一步，采用内核线程来实现内存页替换机制，使得用户进程在快用完内存后，可以通过内存页替换机制把不常用的页换出到硬盘swap分区中，常用的页保存在内存中，保持系统中有足够的内存给用户进程使用。

## proj11概述

### 实现描述

proj11是lab3的第六个project。它在proj10.4的基础上实现了基于内核线程的内存页替换机制，主要扩展设计了专门用于执行内存页替换的内核线程kswapd，并增加了等待队列、扩展了进程控制块的成员变量mm的等，使得在用户进程申请存不足或系统空闲内存不足的情况下，通过执行kswapd内存线程，实现内存页替换，把不常用的页放到硬盘swap分区上，给系统提供足够的空闲空间。

### 项目组成

    proj11
    ├── ……
    │   ├── mm
    │   │   ├── ……
    │   │   ├── pmm.c
    │   │   ├── swap.c
    │   │   ├── swap.h
    │   │   ├── vmm.c
    │   │   └── vmm.h
    │   ├── process
    │   │   ├──……
    │   │   ├── proc.c
    │   │   └── proc.h
    │   └── sync
    │        ├── ……
    │        ├── wait.c
    │        └── wait.h
    └── user
        ├── cowtest.c
        ├── swaptest.c
        └── ……

    17 directories, 114 files

相对于proj10.4，proj11在内核方面主要增加了有关kswapd内核线程和相关函数以及等待队列实现，在用户程序方面，增加测试ucore的COW实现的用户程序cowtest.c和测试内存页置换实现的swaptest.c。主要修改和增加的文件如下：

* kern/mm/pmm.c：扩展了alloc_pages函数，使得它能够在没有获得所需空闲内存页后，进一步调用tre_free_pages来要求ucore释放足够的空闲页，从而再次要求所需空闲页，直到要求得到满足为止。
* kern/mm/swap.[ch]：更新try_free_pages的实现，完成让当前进程睡眠，并唤醒kswapd内核线程，让它完成对空闲页的回收。同时实现了内核线程kswapd的执行主体kswapd_main函数，此函数完成具体的内存页置换机制。
* kern/sync/wait.[ch]：实现等待队列机制，使得内存页等资源无法得到满足的进程能够处于等待状态，并在资源得到满足后让进程继续执行。
* kern/mm/vmm.[ch]：扩展了mm_struct结构，并修改相关函数，使得所有进程的成员变量mm能够链入到全局mm_struct结构的链表proc_mm_list中。
 
### 编译运行

编译并运行proj11的命令如下：

    make
    make qemu
  
则可以得到如下显示界面

    (THU.CST) os is loading ...

    Special kernel symbols:
    ……
    check_vmm() succeeded.
    ide 0:      10000(sectors), 'QEMU HARDDISK'.
    ide 1:     262144(sectors), 'QEMU HARDDISK'.
    check_swap() succeeded.
    ……
    ++ setup timer interrupts
    kernel_execve: pid = 3, name = "swaptest".
    buffer size = 00500000
    parent init ok.
    child 9 fork ok, pid = 13.
    child 8 fork ok, pid = 12.
    child 7 fork ok, pid = 11.
    child 6 fork ok, pid = 10.
    child 5 fork ok, pid = 9.
    child 4 fork ok, pid = 8.
    child 3 fork ok, pid = 7.
    child 2 fork ok, pid = 6.
    child 1 fork ok, pid = 5.
    child 0 fork ok, pid = 4.
    check cow ok.
    round 0
    round 1
    round 2
    round 3
    round 4
    child check ok.
    wait ok.
    check buffer ok.
    swaptest pass.
    all user-mode processes have quit.
    init check memory pass.
    kernel panic at kern/process/proc.c:430:
        initproc exit.

    Welcome to the kernel debug monitor!!
    Type 'help' for a list of commands.
    K>

表面上看不出上述输出对内存页置换算法实现的具体体现。不过通过Makefile和对swaptest.c程序的分析，还是能够看出proj11的执行与其他进程的执行不同：

    Makefile:
    ……
    QEMUOPTS = -m 48m -hda $(UCOREIMG) -drive file=$(SWAPIMG),media=disk,cache=writeback
    swaptest.c
    ……
    const int size = 5 * 1024 * 1024;
    char *buffer;
    ……
    main(void){
    ……
    (buffer = malloc(size))
    ……
        for (i = 0; i < pids; i ++) {
            if ((pid[i] = fork()) == 0) {
    ……
    }

通过Makefile，可以看到qemu只模拟出了48MB的物理内存空间，但swaptest.c创建了10个子进程，且每个子进程都会复制全局变量buffer，且会对buffer中的所有元素进行写操作。由于每个buffer的空间大小为5MB，所以10个子进程和1个父进程的buffer所占虚拟空间总和为55MB，大于实际的48MB物理内存空间。而在操作系统设计上，用户进程的用户空间是没必要都保存在内存中，这使得必须把某些页换出到硬盘swap分区才能确保所有子进程都能正常执行完毕。为此，我们还需进一步分析proj11中ucore具体的内存页置换机制的实现和执行过程。下面将从实现方面对此进行进一步阐述。