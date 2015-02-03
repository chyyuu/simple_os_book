# proj8：支持页换入换出

## proj8项目组成

编译并运行proj8的命令如下：

    make
    make qemu
  
则可以得到如下显示界面

    proj8
    │   ├── driver
    │   │   ├── …
    │   │   ├── ide.c
    │   │   └── ide.h
    │   ├── fs
    │   │   ├── fs.h
    │   │   ├── swapfs.c
    │   │   └── swapfs.h
    │   ├── mm
    │   │   ├── ……
    │   │   ├── memlayout.h
    │   │   ├── pmm.c
    │   │   ├── swap.c
    │   │   ├── swap.h
    │   │   ├── vmm.c
    │   │   └── vmm.h
    │   ├── sync
    │   │   └── sync.h
    │   └── trap
    │       ├── trap.c
    │       └── ……
    ├── libs
    │   ├── hash.c
    │   └── ……
    ├── ……

相对于proj7，proj8主要修改和增加的文件如下：

- ide.[ch]：实现了对IDE硬盘的PIO方式的扇区读写功能，用于支持把页换入和换出硬盘。
- swapfs.[ch]：根据页和硬盘扇区的映射关系，实现了在IDE硬盘上的swap文件组织，并实现了把页写入swap文件和从swap文件读入页的功能。需要ide.[ch]的支持。
- swap.[ch]：参考Linux2.4的页替换策略，实现了一个简化的双链表页替换策略。
- memlayout.h：修改Page等关键数据结构，支持双链页替换策略。
- pmm.c：修改page\_remove\_pte函数，支持双链页替换策略。
- vmm.c：修改do\_pgfault函数，支持页的换入换出。
- sync.h：增加lock/unlock支持，支持页的换入换出过程不会出现race condition现象。

## proj8编译运行 

    (THU.CST) os is loading ...

    Special kernel symbols:
      entry  0xc010002c (phys)
      etext  0xc010dfec (phys)
      edata  0xc012faa8 (phys)
      end    0xc0132e20 (phys)
    Kernel executable memory footprint: 204KB
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
    check_vma_struct() succeeded!
    page fault at 0x00000100: K/W [no page found].
    check_pgfault() succeeded!
    check_vmm() succeeded.
    ide 0:      10000(sectors), 'QEMU HARDDISK'.
    ide 1:     262144(sectors), 'QEMU HARDDISK'.
    page fault at 0x00000000: K/W [no page found].
    page fault at 0x00000000: K/W [no page found].
    page fault at 0x00001001: K/W [no page found].
    page fault at 0x00001000: K/R [no page found].
    page fault at 0x00000000: K/R [no page found].
    check_swap() succeeded.
    ++ setup timer interrupts
    100 ticks
  
check_swap函数对ucore在proj8中建立的双链页面置换策略进行了测试，验证了其正确性，下面我们将从原理和实际实现两个方面来分析proj8中实现的页面置换算法。