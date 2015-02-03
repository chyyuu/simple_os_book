# 【实现】创建并执行用户线程

## 数据结构扩展：进程控制块和用户线程数据结构

由于ucore采用的是内核级线程模型，所以一个用户线程有一个进程控制块，但由于用户线程不同于用户进程，所以要对已有进程控制块进行简单扩展，这个扩展其实就是要表达共享了同一进程的线程组的关系：

    struct proc_struct {
    // the threads list including this proc which share resource
    list_entry_t thread_group;                   
    };

这样便于查找属于同一用户进程的所有用户线程。另外，属于同一用户进程的用户线程能够共享的进程控制块的主要成员变量包括：

    struct mm_struct *mm;  // Process's memory management field
    uintptr_t cr3; // CR3 register: the base addr of Page Directroy Table(PDT)
    
这样确保了属于同一用户进程的用户线程能共享同一用户地址空间。在对于其他一些与线程执行相关的成员变量，比如state、kstack、tf等，都有各自独立的数据存在。由于属于同一用户进程的不同用户线程除了在内核地址空间需要有不同的内核栈空间外，在用户地址空间也需要有不同的用户栈空间。为此，我们还需有一个数据结构来描述。ucore把这个数据机构放在用户态函数库中（user/libs/thread.h）：

    typedef struct {
        int pid;
        void *stack;
    } thread_t;

thread_t是对进程控制块的补充，pid是此线程的id标识（与进程控制块的pid一致），stack是用户栈的起始地址。通过这两方面的扩展，在数据结构层面就已经做好对用户线程的支持了。

## 创建用户线程

创建用户线程的执行流程重用了创建用户进程的执行过程，但有一些微小的差别，下面我们逐一进行分析。用户态函数库提供了thread函数来给应用程序提供创建线程的接口。

    int
    thread(int (*fn)(void *), void *arg, thread_t *tidp) {
        if (fn == NULL || tidp == NULL) {
            return -E_INVAL;
        }
        int ret;
        uintptr_t stack = 0;
        if ((ret = mmap(&stack, THREAD_STACKSIZE, MMAP_WRITE | MMAP_STACK)) != 0) {
            return ret;
        }
        assert(stack != 0);

        if ((ret = clone(CLONE_VM | CLONE_THREAD, stack + THREAD_STACKSIZE, fn, arg)) < 0) {
            munmap(stack, THREAD_STACKSIZE);
            return ret;
        }

        tidp->pid = ret;
        tidp->stack = (void *)stack;
        return 0;
    }

从中可以看出，thread函数首先需要给用户线程分配用户栈，这里采用的是mmap函数（最终访问sys_mmap系统调用）来完成栈空间分配。其实ucore并没有真的给用户线程分配栈空间，这里采用了Demanding Paging（按需分页）技术来减少分配栈空间的时间和空间开销。另外，还调用了clone函数来完成用户线程的创建，clone进一步调用了sys_clone系统调用接口来要求ucore完成创建线程的服务。sys_clone与创建进程的sys_fork系统调用接口有何区别？它们的区别是创建标志位clone_flags：

* 调用clone创建线程的创建标志位：CLONE_VM | CLONE_THREAD
* 调用fork创建进程的创建标志位 ：0

【注意】另外clone函数要完成的具体工作是放在/usr/libs/clone.S中的函数__clone来实现的。为何__clone函数的内容不直接放到clone函数中用C语言来实现呢？这里其实只能用汇编来实现。因为对于用户进程而言，采用fork函数创建用户进程时，对子进程用户空间的设置采用的是整体复制或基于COW机制的整体共享方式，这样就可保证不同进程的堆和栈最终位于不同的用户地址空间。而对于用户线程而言，它需要共享父进程的地址空间，但又需要有自己的栈空间（此空间虽然父进程也可以“看到”，但不能用，只能归线程自己专用），所以在访问sys_clone系统调用前，用户线程用的是父进程的用户堆栈，在此系统调用返回后，用户线程已经被创建并开始在用户态执行，此时sp已经指向了新进程建立的新用户栈（见usr/libs/thread.c），而不是父进程的用户栈，这也就意味着在从系统调用返回后，子进程已经无法读位于父进程栈上的局部变量等数据。这样新线程需要使用寄存器（其实全局变量也行，只要避免使用位于进程栈上的局部变量即可）来进行数据处理，完成用户线程的继续执行。为了能够精确控制这个执行过程，不得不采用汇编来写，如果用C语言来写，你无法确保编译器不创建或使用局部变量来完成处理过程。

在内核中，创建线程的服务和创建进程的服务都是通过do_fork来实现的，而这个创建标志位clone_flags就决定了如何创建线程，查看do_fork函数：

    int
    do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
        ……
        if (copy_mm(clone_flags, proc) != 0) {
            goto bad_fork_cleanup_kstack;
        }
         ……
        {
              ……
            if (clone_flags & CLONE_THREAD) {
                list_add_before(&(current->thread_group), &(proc->thread_group));
            }
        }
     ……
    }

如果进一步分析copy_mm函数，如果clone_flags有CLONE_VM位，则执行：

    ……
        mm_count_inc(mm);
        proc->mm = mm;
        proc->cr3 = PADDR(mm->pgdir);
    ……

后两条语句说明了被创建的新线程重用了当前进程控制块的mm成员变量，并重用同样的页表。而如果clone_flags有CLONE_THREAD位，则会把被创建的新线程的进程控制块成员变量thread_group链接到当前进程控制块的牵头的链表thread_group中在，这样所有当前进程创建的线程都会在当前进程牵头的链表thread_group中找到。而在其他操作中，创建线程与创建进程的处理逻辑是一样的。

## 退出用户线程

在退出线程方面，与进程退出相比，区别不大。只是在执行do_exit的时候，调用de_thread(current)函数，进一步把自身从线程组链表中删除，其他方面都与进程执行do_exit一致；而父进程执行用户库函数thread_wait来通过sys_wait系统调用接口进一步调用内核函数do_exit完成对退出的子进程资源的最后回收。与进程的wait函数相比，主要的区别是：用户库函数thread_wait通过munmap函数完成了对线程用户栈空间的回收。与proj12以前实现的do_exit函数相比，主要的区别是：在查找是否有子线程的执行状态处于PROC_ZOMBIE时，除了搜索此进程的每个子进程外，还搜索此进程所属线程组的每个线程的所有子进程。其他方面的处理都是大致相同的。
