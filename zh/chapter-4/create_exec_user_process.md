# 创建并执行用户进程

## 实验目标

到proj10为止，ucore还一直在核心态“打转”，没有到用户态执行。其实这也是对操作系统的要求，操作系统就要呆在核心态，才能管理整个计算机系统。但应用程序员也需要编写各种应用软件，且要在计算机系统上运行。如果把这些应用软件都作为内核线程来执行，那系统的安全性就无法得到保证了。操作系统的观点是：操作系统程序员编写的操作系统模块是可信的、高效的，对计算机的物理资源了如指掌，可在计算机的核心态执行；但应用程序员编写的应用软件是不可信的，不必了解计算机的物理资源，且需要操作系统提供服务，故放在用户态执行，无法轻易破坏操作系统和其他用户态的进程通过系统调用获得操作系统的服务。所以，ucore要提供用户态进程的创建和执行机制，给应用程序执行提供一个用户态运行环境。

## proj10.1概述

### 实现描述

proj10.1是lab3的第二个project。它在proj10的基础上实现了对用户态进程的支持，主要扩展设计了用户进程执行的用户地址空间、对用户进程访存错误的异常处理、提供用户进程执行效率的按需分页和写时复制的支持、加载并执行依附在ucore内核文件的用户执行程序、实现系统调用机制等。

### 项目组成

    proj10.1
    ├── ……
    ├── kern
    │   ├── ……
    │   ├── mm
    │   │   ├── memlayout.h
    │   │   ├── vmm.c
    │   │   └── vmm.h
    │   ├── process
    │   │   ├── proc.c
    │   │   ├── proc.h
    │   │   └── ……
    │   ├── syscall
    │   │   ├── syscall.c
    │   │   └── syscall.h
    │   └── trap
    │       ├── trap.c
    │       └── ……
    └── user
        ├── badsegment.c
        ├── divzero.c
        ├── faultread.c
        ├── faultreadkernel.c
        ├── hello.c
        ├── libs
        │   ├── initcode.S
        │   ├── panic.c
        │   ├── stdio.c
        │   ├── syscall.c
        │   ├── syscall.h
        │   ├── ulib.c
        │   ├── ulib.h
        │   └── umain.c
        ├── pgdir.c
        ├── softint.c
        ├── testbss.c
        └── yield.c

	17 directories, 97 files
    
相对于proj10，proj10.1主要增加了有关系统调用实现的syscall.[ch]和测试ucore对用户进程支持的各种用户态程序和库文件，并对相关的内核文件进行了修改。主要修改和增加的文件如下：

- mm/memlayout.h：定义了用户态空间的范围，具体可看“Virtual memory map”的ASCII图注释。
- mm/vmm.[ch]：在vmm.h文件中，扩展了mm_struct数据结构，支持多进程对mm_struct的引用计数和互斥访问，和针对mm_struct结构的引用计数操作和互斥操作；在vmm.c中，主要增加了部分函数防止多进程（比如父子进程、多线程等）同时访问进程的mm进程内存管理数据结构。
- process/proc.[ch]：对一系列进程管理相关函数进行了扩展，并新实现了部分函数。这是内核改动最大的部分。
- syscall/syscall.[ch]：新增加的部分，提供用户态进程所需的系统服务的操作系统层接口，根据系统调用号，在转到具体的服务功能函数中完成用户态进程的服务请求。
- trap/trap.c：增加对系统调用的初始化和处理，扩展对访存错误异常的处理。
- user/*：实现应用程序所需的基本库函数支持，提供实现系统调用的用户层接口。

### 编译运行

编译并运行proj10.1的命令如下：

    make
    make qemu
  
则可以得到如下显示界面

    (THU.CST) os is loading ...

    Special kernel symbols:
      entry  0xc010002c (phys)
      etext  0xc0114ba3 (phys)
      edata  0xc018656f (phys)
      end    0xc018b934 (phys)
    Kernel executable memory footprint: 559KB
    memory management: buddy_pmm_manager
    ……
    check_mm_shm_swap() succeeded.
    ++ setup timer interrupts
    kernel_execve: pid = 1, name = "hello".
    Hello world!!.
    I am process 1.
    hello pass.
    kernel panic at kern/process/proc.c:379:
        initproc exit.

    Welcome to the kernel debug monitor!!
    Type 'help' for a list of commands.
    K>

上述执行输出相对于proj10没有太多变化，只是出现了“kernel_execve: … hello pass”等字符串。但其实在其背后，涉及创建用户态进程，把执行代码加载到用户态线程地址空间，执行系统调用等一系列操作。为了更好地理解proj10.1的设计和实现方案，我们先需要在了解一下用户态进程的特征。下面我们将从原理和实现两个方面对此进行进一步阐述。
