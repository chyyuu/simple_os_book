# 【实现】实模式到保护模式的切换

BIOS把bootloader从硬盘（即是我们刚才生成的ucore.img）的第一个扇区（即是我们刚才生成的bootblock）读出来并拷贝到内存一个特定的地址0x7c00处，然后BIOS会跳转到那个地址（（即CS=0，EIP=0x7c00））继续执行。至此BIOS的初始化工作做完了，进一步的工作交给了ucore的bootloader。

bootloader从哪里开始执行呢？我们【实验2-2 编译运行bootloader】中描述make工作过程的第五步就是生成了一个bootblock.asm，它的前面几行是：
```
    obj/bootblock.o:     file format elf32-i386
    Disassembly of section .text:
    00007c00 <start>:
    .set CR0_PE_ON,      0x1         # protected mode enable flag
    .globl start
    start:
      .code16                     # Assemble for 16-bit mode
      cli                         # Disable interrupts
      7c00:	fa                    cli
```
上述代码片段指出了bootblock（即bootloader）在0x7c00虚拟地址（在这里虚拟地址=线性地址=物理地址）处的指令为“cli”，如果读者再回头看看bootasm.S中的12~15行：
```
	.globl start
    start:
      .code16                     # Assemble for 16-bit mode
      cli                         # Disable interrupts
      cld                         # String operations increment
```
就可以发现二者是完全一致的。而这个虚拟地址的设定是通过链接器ld完成的，我们【实验2-2 编译运行bootloader】中描述make工作过程的第四步：
    i386-elf-ld  -N -e start -Ttext 0x7C00 -o obj/bootblock.o obj/bootasm.o obj/bootmain.o
 
其中“-e start”指出了bootblock的入口地址为start，而“-Ttext 0x7C00”指出了代码段的起始地址为0x7c00，这也就导致start位置的虚拟地址为0x7c00。

   从0x7c00开始，bootloader用了21条汇编指令完成了初始化和切换到保护模式的工作。其具体步骤如下：
 
1. 关中断，并清除方向标志，即将DF置“0”，这样(E)SI及(E)DI的修改为增量。
        cli      # Disable interrupts
        cld      # String operations increment
  
2. 清零各数据段寄存器：DS、ES、FS
          xorw    %ax,%ax             # Segment number zero
          movw    %ax,%ds             # -> Data Segment
          movw    %ax,%es             # -> Extra Segment
          movw    %ax,%ss             # -> Stack Segment
    
3. 使能A20地址线，这样80386就可以突破1MB访存现在，而可访问4GB的32位地址空间了。可回顾2.2.1节的【历史：A20地址线与处理器向下兼容】。
        seta20.1:
          inb     $0x64,%al               # Wait for not busy
          testb    $0x2,%al
          jnz     seta20.1
          movb    $0xd1,%al               # 0xd1 -> port 0x64
          outb    %al,$0x64
        seta20.2:
          inb     $0x64,%al               # Wait for not busy
          testb   $0x2,%al
          jnz     seta20.2
          movb    $0xdf,%al               # 0xdf -> port 0x60
          outb    %al,$0x60
4. 建立全局描述符表（可回顾2.2.3节对全局描述符表的介绍），使能80386的保护模式（可回顾2.2.4节对CR0寄存器的介绍）。lgdt指令把gdt表的起始地址和界限（gdt的大小-1）装入GDTR寄存器中。而指令“movl %eax，%cr0”把保护模式开启位置为1，这时已经做好进入80386保护模式的准备，但还没有进入80386保护模式
          lgdt    gdtdesc
          movl    %cr0, %eax
          orl     $CR0_PE_ON, %eax
          movl    %eax, %cr0
        
	gdtdesc指出了全局描述符表（可以看成是段描述符组成的一个数组）的起始位置在gdt符号处，而gdt符号处放置了三个段描述符的信息
        gdt:
          SEG_NULLASM                             # null seg
          SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)        # code seg
          SEG_ASM(STA_W, 0x0, 0xffffffff)              # data seg
每个段描述符占8个字节，第一个是NULL段描述符，没有意义，表示全局描述符表的开始，紧接着是代码段描述符（位于全局描述符表的0x8处的位置），具有可读（STA_R）和可执行（STA_X）的属性，并且段起始地址为0，段大小为4GB；接下来是数据段描述符（位于全局描述符表的0x10处的位置），具有可读（STA_R）和可写（STA_W）的属性，并且段起始地址为0，段大小为4GB。

5. 通过长跳转指令进入保护模式。80386在执行长跳转指令时，会重新加载$PROT_MODE_CSEG的值（即0x8）到CS中，同时把$protcseg的值赋给EIP，这样80386就会把CS的值作为全局描述符表的索引来找到对应的代码段描述符，设定当前的EIP为0x7c32(即protcseg标号所在的段内偏移)， 根据2.2.3节描述的分段机制中虚拟地址到线性地址转换转换的基本过程，可以知道线性地址（即物理地址）为：
        gdt[CS].base_addr+EIP=0x0+0x7c32=0x7c32
        ljmp    $PROT_MODE_CSEG, $protcseg
      
6. 执行完上面的这条汇编语句后，bootloader让80386从实模式进入了保护模式。由于在访问数据或栈时需要用DS/ES/FS/GS和SS段寄存器作为全局描述符表的下标来找到相应的段描述符，所以还需要对DS/ES/FS/GS和SS段寄存器进行初始化，使它们都指向位于0x10处的段描述符（即gdt中的数据段描述符）。
          movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
          movw    %ax, %ds                # -> DS: Data Segment
          movw    %ax, %es                # -> ES: Extra Segment
          movw    %ax, %fs                # -> FS
          movw    %ax, %gs                # -> GS
          movw    %ax, %ss                # -> SS: Stack Segment

	在保护模式下，所有的内存寻址将经过分段机制的存储管理来完成，即每个虚拟地址访问将经过分段机制转换成线性地址，由于这时还没有启动分页模式，所以线性地址就是物理地址。
