# proj7：支持缺页异常和VMA结构

## proj7项目组成

    proj7
    |   |-- init
    |   |   `-- init.c   
    |   |-- mm

    |   |   |-- pmm.c
    |   |   |-- pmm.h
    |   |   |-- vmm.c
    |   |   `-- vmm.h
    |   |-- sync
    |   |   `-- sync.h
    |   `-- trap
    |       |-- trap.c

    |-- libs
    |   `-- x86.h

相对与proj6，proj7主要修改和增加的文件如下：

- init.c：在kern\_init中增加调用初始化虚存管理函数vmm\_init
- pmm.[ch]：增加pgdir\_alloc\_page函数，完成分配一个空闲物理页，并设置好页表项，完成正确的虚拟地址到物理地址的转换；
- trap.c：完成对缺页异常的基本操作，调用vmm.c中的do\_pgfault函数完成具体的缺页处理；
- x86.h：完成对控制寄存器CR1和CR2的读操作；
- vmm.[ch]：新增的文件，主要是建立vma\_struct结构，用于描述不存在的虚拟内存，并完成针对此结构的相关操作函数。

## proj7编译运行

编译并运行proj7的命令如下：

    make
    make qemu
  
则可以得到如下显示界面

    chenyu@chenyu-laptop:~/oscourse/branches/testing/chyyuu/proj7$ make qemu
    (THU.CST) os is loading ...

    Special kernel symbols:
      entry  0xc010002c (phys)
      etext  0xc010ae5f (phys)
      edata  0xc0127aa0 (phys)
      end    0xc0128cbc (phys)
    Kernel executable memory footprint: 164KB
    memory managment: buddy_pmm_manager
    e820map:
      memory: 0009f400, [00000000, 0009f3ff], type = 1.
      memory: 00000c00, [0009f400, 0009ffff], type = 2.
      memory: 00010000, [000f0000, 000fffff], type = 2.
      memory: 07efd000, [00100000, 07ffcfff], type = 1.
      memory: 00003000, [07ffd000, 07ffffff], type = 2.
      memory: 00040000, [fffc0000, ffffffff], type = 2.
    check_alloc_page() succeeded!
    check_pgdir() succeeded!
    check_boot_pgdir() succeeded!
    -------------------- BEGIN --------------------
    PDE(0e0) c0000000-f8000000 38000000 urw
      |-- PTE(38000) c0000000-f8000000 38000000 -rw
    PDE(001) fac00000-fb000000 00400000 -rw
      |-- PTE(000e0) faf00000-fafe0000 000e0000 urw
      |-- PTE(00001) fafeb000-fafec000 00001000 -rw
    --------------------- END ---------------------
    check_slab() succeeded!
    size of struct mm_struct is 24, size of struct vma_struct is 40
    check_vma_struct() succeeded!
    page fault at 0x00000100: K/W [no page found].
    check_pgfault() succeeded!
    check_vmm() succeeded.
    ++ setup timer interrupts
    100 ticks
    100 ticks

通过上图，我们可以看到ucore在check_vma_struct函数中完成基于vma_struct结构的数据创建等操作，确保能够正确建立vma_struct结构，并在成功测试后打印“check_vma_struct() succeeded!”；接下来ucore创建一个描述了虚拟地址0~4K的vma_struct结构，这个0虚拟地址起始的虚拟页没有对应的物理页，所以在实际访问这个虚拟地址的时候会产生缺页异常，中断处理例程会经过如下调用：

    vectorXXX(vectors.S)-->\__alltraps(trapentry.S)--> trap(trap.c)-->trap_dispatch(trap.c)—
    -->pgfault_handler(trap.c)-->print_pgfault(trap.c)
  
来显示出错的位置和原因“page fault at 0x00000100: K/W [no page found].”，即在内核态对虚存地址0x100处执行写操作出现了缺页异常。并进一步调用do_pgfault函数来检测时候此虚拟地址属于某个vma_struct描述的范畴，如果是，则会分配一个物理页来对应此虚拟地址所在的虚拟页，并返回继续执行引起缺页异常的指令。如果测试能够正确执行对应的写操作指令，表明能正确处理缺页异常，则显示

	“check_pgfault() succeeded!”和“check_vmm() succeeded.”。
