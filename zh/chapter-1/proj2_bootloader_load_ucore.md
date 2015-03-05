# 可读ELF格式文件的baby bootloader

## 实验目标
接下来，我们需要完成一个能够读取位于硬盘中OS的代码内容并加载运行OS的bootloader，这需要bootloader能够读取硬盘扇区中的数据。由于OS采用ELF执行文件格式，所以bootloader能够解析ELF格式文件，把其中的代码和数据放到内存中正确的位置。Bootloader虽然增加了这么多功能，但整个bootloader的大小还是必须小于512个字节，这样才能放到只有512字节大小的硬盘主引导扇区中。
> ucore内核不一定非要是ELF格式，基于binary格式的ucore内核也可以被bootloader识别与加载。

通过分析和实现这个bootloader，读者对设备管理的方式会有更加深入的理解，掌握bootloader/操作系统等底层系统软件是如何在保护模式下通过PIO（Programming I/O，可编程I/O）方式访问块设备硬盘；理解如何在保护模式下解析并加载一个简单的ELF执行文件。


## proj2/3概述

### 实现描述  
proj2基于proj1的主要实现一个可读硬盘并可分析ELF执行文件格式的bootloader，由于bootloader要放在512字节大小的主引导扇区中，所以不得不去掉部分显示输出的功能，确保整个bootloader的大小小于510个字节（最后两个字节用于硬盘主引导扇区标识，即“55AA”）。proj3在proj2的基础上增加了一个只能显示字符的第一代幼稚型操作系统ucore，用来验证proj2实现的bootloader能够正确从硬盘读出ucore并加载到正确的内存位置，并能把CPU控制权交给ucore。ucore在获得CPU控制权后，能够在保护模式下显示一个字符串，表明自己能够正常工作了

### 项目组成  
这里我们分了两个project来完成此事。proj2是一个可分析ELF执行文件格式的例子，proj2整体目录结构如下所示：
```
        proj2/
        |-- boot
        |   |-- asm.h
        |   |-- bootasm.S
        |   `-- bootmain.c
        |-- libs
        |   |-- elf.h
        |   |-- types.h
        |   `-- x86.h
        |-- Makefile
        ……
```
proj2与proj1类似，只是增加了libs/elf.h文件，并且bootmain.c中增加了对ELF执行文件的简单解析功能和读磁盘功能。
    
proj3建立在proj2基础之上，增加了一个只能显示字符的ucore操作系统，让bootloader能够把这个操作系统从硬盘上读到内存中，并跳转到ucore的起始处执行ucore的功能。proj3整体目录结构如下所示：
```    
        proj3
        |-- boot
        |   |-- asm.h
        |   |-- bootasm.S
        |   `-- bootmain.c
        |-- kern
        |   |-- driver
        |   |   |-- console.c
        |   |   `-- console.h
        |   |-- init
        |   |   `-- init.c
        |   `-- libs
        |       `-- stdio.c
        |-- libs
        |   |-- elf.h
        |   |-- error.h
        |   |-- printfmt.c
        |   |-- stdarg.h
        |   |-- stdio.h
        |   |-- string.c
        |   |-- string.h
        |   |-- types.h
        |   `-- x86.h
        |-- Makefile
        ……
```
proj3相对于proj2增加了ucore相关的文件，下面简要说明一下：
 * libs目录下的printfmt.c：完成类似C语言的printf中的格式化处理；
 * libs目录下的string.c：完成类似C语言的str\*\*\*相关的字符串处理函数；
 * libs目录下的st*.h：是支持上述两个库函数（可被内核和用户应用共享）的.h文件；
 * kern/init目录下的init.c：完成ucore的初始化工作；
 * kern/driver目录下的console.c：提供并口/串口/CGA方式的字符输出的console驱动；
 * kern/libs/stdio.c：提供内核方式下的的cprintf函数功能；
	 
### 编译运行
那接下来是如何生成一个包含了bootloader和ucore操作系统的硬盘镜像呢？我们先修改proj3目录下的Makefile，在其第五行
```
        V       := @
```
的最前面增加一个“#”（目的是让make工具程序详细显示整个project的编译过程），这样就把这行给注释了。然后在proj3目录下执行make，可以看到：
```
        ……
        ld -m    elf_i386 -Ttext 0x100000 -e kern_init -o bin/kernel obj/kern/init/init.o obj/kern/libs/printf.o obj/kern/driver/console.o obj/libs/printfmt.o obj/libs/string.o
        ……
        dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrunc
```
这两步是生成ucore的关键。第一步把ucore涉及的各个.o目标文件链接起来，并在bin目录下形成ELF文件格式的文件kernel，这就是我们第一个ucore操作系统，而且设定ucore的执行入口地址在0x10000，即kern_init函数的起始位置。这也就意味着bootloader需要把读出的kernel文件的代码段+数据段放置在0x10000起始的内存空间。第二步是把bin目录下的kernel文件直接覆盖到ucore.img（虚拟硬盘的文件）的bootloader所处扇区（即第一个扇区，主引导扇区）之后的扇区（第二个扇区）。如果一个扇区大小为512字节，这kernel覆盖的扇区数为上取整（kernel的大小/512字节）。

编译后运行proj3的示意图如下所示：
	
    ![qemu_cha1](figures/qemu_cha2.jpg)
  
