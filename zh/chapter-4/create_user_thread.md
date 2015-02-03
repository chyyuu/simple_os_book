# 创建并执行用户线程

## 实验目标

到proj12为止，ucore还一直没有用户线程。而用户线程与用户进程的区别在于操作系统用户进程管理除了涉及与执行过程相关的调度、进程上下文切换、执行状态变化外，还需管理内存、文件等资源，而用户线程只管理与执行过程相关的调度、上下文切换、执行状态变化。这样使得在执行线程创建、删除和线程上下文切换时的开销比对进程做类似的事情要少很大的开销。从而在操作系统的用户线程管理下，可以让应用程序开发员开发多线程应用软件的执行效率更高。

为了支持用户线程，我们还需对现有的进程管理进行有限扩展，在了解线程基本原理的情况下，设计并实现ucore对用户线程的基本支持。

## 概述

### 实现描述

proj12是lab3的最后一个project。它在proj10.1（中间还有proj10.2/10.3/10.4/11）的基础上实现了对用户线程的支持，主要参考了Linux的线程实现思路，把线程作为一个共享内存等资源的轻量级进程看待，扩展设计了进程控制块中支持用户线程的成员变量和与进程管理相关的系统调用，使得在现有进程管理的基础上，做相对较小的改动，就支持线程模型了。

### 项目组成

    proj12
    ├── …
    │   ├── process
    │   │   ├── proc.c
    │   │   ├── proc.h
    │   │   └── …
    │   ├── syscall
    │   │   ├── syscall.c
    │   │   └── …
    └── user
        ├── libs
        │   ├── clone.S
        │   ├── lock.h
        │   ├── thread.c
        │   ├── thread.h
        │   ├── ulib.c
        │   └── ulib.h
        ├── threadfork.c
        ├── threadtest.c
        ├── threadwork.c
        └── …

相对于proj11，主要增加和扩展的文件如下：

* kern/proc.[ch]：扩展进程控制块，增加线程组成员变量，并扩展和增加与线程管理相关的函数；
* kern/syscall.c：增加用于线程创建的sys_clone系统调用；
* user/libs/*.[chS]：实现用户态创建线程的库调用函数、访问系统调用函数；
* user/thread*.c：线程支持用户测试用例。

### 编译运行

首先确保proj12的kern/proc.c中的user_main函数中的代码为：

    static intuser_main(void *arg) {#ifdef TEST    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);#else    KERNEL_EXECVE(threadtest);#endif    panic("user_main execve failed.\n");}


编译并运行proj12的命令如下：

    make
    make qemu

则可以得到如下显示界面：

    thuos:~/oscourse/ucore/i386/lab3_process/proj12$ make qemu
    (THU.CST) os is loading ...
    ……
    ++ setup timer interrupts
    kernel_execve: pid = 3, name = "threadtest".
    thread ok.
    child ok.
    threadtest pass.
    all user-mode processes have quit.
    init check memory pass.
    kernel panic at kern/process/proc.c:454:
        initproc exit.

    Welcome to the kernel debug monitor!!
    Type 'help' for a list of commands.
    K>

  这其实是ucore首先创建了一个用户进程usermain，然后此用户进程通过调用sys_execv执行的是users/threadtest.c中的代码：

    #include <ulib.h>
	#include <stdio.h>
    #include <thread.h>
	inttest(void *arg) {
    	cprintf("child ok.\n");
		return 0xbee;
    }
	intmain(void) {
    	thread_t tid;
		assert(thread(test, NULL, &tid) == 0);   
        cprintf("thread ok.\n");    
		int exit_code;    
        assert(thread_wait(&tid, &exit_code) == 0 && exit_code == 0xbee);    
		cprintf("threadtest pass.\n");    
        return 0;
	}

usermain用户进程调用了thread用户库函数来创建了一个用户线程test，这个用户线程同享了usermain用户进程的地址空间，然后usermain用户进程就调用thread_wait函数等待用户线程结束。用户线程test在结束执行时，会设置退出码为0xbee。用户进程usermain会检查此退出码，看用户线程是否结束。上述执行过程其实包含了对用户线程整个生命周期的管理。下面我们将从原理和实现两个方面对此进行进一步阐述。

