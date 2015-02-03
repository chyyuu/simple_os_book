#进程调度

## 实验目标

在只有一个或几个CPU的计算机系统中，进程数量一般远大于CPU数量，CPU是一个稀缺资源，多个进程不得不分时占用CPU执行各自的工作，操作系统必须提供一种手段来保证各个进程“和谐”地共享CPU。为此，需要在lab3的基础上设计实现ucore进程调度类框架以便于设计各种进程调度算法，同时以提高计算机整体效率和尽量保证各个进程“公平”地执行作为目标来设计各种进程调度算法。

## proj13/13.1/13.2概述

### 实现描述

project13是lab4的第一个项目，它基于lab3的最后一个项目proj12。主要参考了Linux-2.6.23设计了一个简化的进程调度类框架，能够在此框架下实现不同的调度算法，并在此框架下实现了一个简单的FIFO调度算法。接下来的proj13.1在此调度框架下实现了轮转（Round Robin，简称RR）调度算法，proj13.2在此调度框架下实现了多级反馈队列（Multi-Level Feed Back，简称MLFB）调度算法。  

### 项目组成

    proj13
    ├── kern
    │   ├── ......
    │   ├── process
    │   │   ├──……
    │   │   ├── proc.h
    │   │   └── proc.c
    │   ├── schedule
    │   │   ├── sched.c
    │   │   ├── sched_FCFS.c
    │   │   ├── sched_FCFS.h
    │   │   └── sched.h
    │   └── trap
    │       ├── trap.c
    │       └── ……
    └── user
        ├── matrix.c
        └── ……

    17 directories, 129 files

相对与proj12，proj13增加了3个文件，修改了相对重要的5个文件。主要修改和增加的文件如下：

* process/proc.[ch]：扩展了进程控制块的定义能够把处于就绪态的进程放入到一个就绪队列中，并在创建进程时对新扩展的成员变量进行初始化。
* schedule/sched.[ch]：增加进程调度类的定义和相关进程调度类的共性函数。 
* schedule/sched_FCFS.[ch]：基于进程调度类的FCFS调度算法实例的设计实现；
* schedule/sched.[ch]：实现了一个先来先服务（First Come First Serve）策略的进程调度。
* user/matrix.c：矩阵乘用户测试程序

### 编译运行

编译并运行proj13的命令如下：

    make
    make qemu
  
则可以得到如下显示界面

    (THU.CST) os is loading ...

    Special kernel symbols:
    ……
    ++ setup timer interrupts
    kernel_execve: pid = 3, name = "matrix".
    fork ok.
    pid 4 is running (1000 times)!.
    pid 4 done!.
    pid 5 is running (1400 times)!.
    pid 5 done!.
    ……
    pid 22 is running (33400 times)!.
    pid 22 done!.
    pid 23 is running (33400 times)!.
    pid 23 done!.
    matrix pass.
    all user-mode processes have quit.
    init check memory pass.
    kernel panic at kern/process/proc.c:456:
        initproc exit.

    Welcome to the kernel debug monitor!!
    Type 'help' for a list of commands.
    K>

这其实是在采用简单的FCFS调度方法来执行matrix用户进程，这个matrix进程将创建20个进程来各自执行二维矩阵乘的工作。Ucore将按照FCFS的调度方法，一个一个地按创建顺序执行每个子进程。一个子进程结束后，再调度另外一个子进程运行。这实际上看不出ucore是如何具体实现进程调度类框架和FCFS调度算法的。下面我们首先介绍一下进程调度的基本原理，然后再分析ucore的调度框架和调度算法的实现。
