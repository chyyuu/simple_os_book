# 【实现】vma_struct数据结构和相关操作

在讲述缺页异常处理前，需要建立好虚拟内存空间描述。在proj7之前有关内存的数据结构和相关操作都是直接针对实际存在的资源--物理内存空间的管理，没有从一般应用程序对内存的“需求”考虑，即需要有相关的数据结构和操作来体现一般应用程序对虚拟内存的“需求”。一般应用程序的对虚拟内存的“需求”与物理内存空间的“供给”没有直接的对应关系，ucore是通过缺页异常处理来间接完成这二者之间的衔接。

在ucore中描述应用程序对虚拟内存“需求”的数据结构是vma_struct，以及针对vma_struct的函数操作。这里把一个vma_struct结构的变量简称为vma变量。vma_struct的定义如下：

    struct vma_struct {
        struct mm_struct *vm_mm;
        uintptr_t vm_start;
        uintptr_t vm_end;
        uint32_t vm_flags;
        list_entry_t list_link;
    };

vm_start和vm_end描述了一个连续地址的虚拟内存空间的起始位置和结束位置，这两个值都应该是 PGSIZE 对齐的，而且描述的是一个合理的地址空间范围（即严格确保 vm_start < vm_end 的关系）；list_link是一个双向链表，按照从小到大的顺序把一系列用vma_struct表示的虚拟内存空间链接起来，并且还要求这些链起来的 vma_struct 应该是不相交的，即vma之间的地址空间无交集；vm_flags表示了这个虚拟内存空间的属性，目前的属性包括：

    #define VM_READ	0x00000001 //只读
    #define VM_WRITE	0x00000002 //可读写
    #define VM_EXEC	0x00000004 //可执行
  
以后还会引入如 VM_STACK 的其它属性来支持动态扩展用户栈空间。

vm_mm是一个指针，指向一个比vma_struct更高的抽象层次的数据结构mm_struct，这里把一个mm_struct结构的变量简称为mm变量。这个数据结构表示了包含所有虚拟内存空间的共同属性，具体定义如下

    struct mm_struct {
        list_entry_t mmap_list;
        struct vma_struct *mmap_cache;
        pde_t *pgdir;
        int map_count;
    };
  
mmap_list是双向链表头，链接了所有属于同一页目录表的虚拟内存空间，mmap_cache是指向当前正在使用的虚拟内存空间，由于操作系统执行的“局部性”原理，当前正在用到的虚拟内存空间在接下来的操作中可能还会用到，这时就不需要查链表，而是直接使用此指针就可找到下一次要用到的虚拟内存空间。由于 mmap_cache 的引入，使得 mm_struct 数据结构的查询加速 30% 以上。pgdir 所指向的就是 mm_struct 数据结构所维护的页表。通过访问pgdir可以查找某虚拟地址对应的页表项是否存在以及页表项的属性等。map_count记录 mmap_list 里面链接的 vma_struct 的个数。

涉及mm_struct的操作函数比较简单，只有mm_create和mm_destroy两个函数，从字面意思就可以看出是是完成mm_struct结构的变量创建和删除。在mm_create中用kmalloc分配了一块空间，所以在mm_destroy中也要对应进行释放。在ucore运行过程中，会产生描述虚拟内存空间的vma_struct结构，所以在mm_destroy中也要进对这些mmap_list中的vma进行释放。涉及vma_struct的操作函数也比较简单，主要包括三个：

- vma\_create--创建vma
- insert\_vma\_struct--插入一个vma
- find\_vma--查询vma。

vma\_create函数根据输入参数vm\_start、vm\_end、vm\_flags来创建并初始化描述一个虚拟内存空间的vma_struct结构变量。insert_vma_struct函数完成把一个vma变量按照其空间位置[vma->vm_start,vma->vm_end]从小到大的顺序插入到所属的mm变量中的mmap_list双向链表中。find_vma根据输入参数addr和mm变量，查找在mm变量中的mmap_list双向链表中某个vma包含此addr，即vma->vm_start<= addr <vma->end。这三个函数与后续讲到的缺页异常处理有紧密联系。 
