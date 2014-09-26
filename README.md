操作系统简单实现与基本原理 — 基于ucore
===============
## 为什么要写这本书

对于在校的学生和已经参加工作的工程师而言，能否以较小的时间和精力比较全面地了解操作系统呢？陆游老夫子说过“纸上得来终觉浅，绝知此事要躬行”，也许在了解基本的操作系统概念和原理基础上，通过实际动手来一步一步分析、设计和实现一个微型化的操作系统，会发现操作系统原来如此，概念原理和实际实现之间有紧密的联系和巨大的差异。
一方面现在的操作系统课本越来越庞大和抽象，反而忽视了实践。要知道，操作系统的设计实现是在没有教科书的情况下完成的。换句话说，现有操作系统的实现，再有操作系统的课本。而另一方面实际的操作系统相当庞大，如Linux、Windows等，都是上百万行的源代码规模，实现这些软件的目的是给人用的，不是给人学的。能否在这两方面找到一个平衡？

早期的UNIX操作系统和MIT教授 Frans Kaashoek 博士等基于UNIX v6设计的xv6操作系统给了我们启发：对一个计算机专业的本科生而言，设计实现一个操作系统有挑战但是可行！本书想进行这样的教学尝试，以设计实现一个微型但全面的“麻雀”操作系统—ucore为基本目标，以增量式地完成各种基于ucore操作系统的实验为实践过程，以在此过程中逐步介绍的操作系统的基本概念和原理为实践指导，做到有“理”可循和有“码”可查，最终让读者了解和掌握操作系统的原理、设计与实现。

## ucore的开发过程

### 历史
---------
写一个教学OS的初衷是陈渝老师和向勇老师想参考MIT的xv6/JOS开发一个能够与OS课程教材向配套的OS实验环境。没有直接采用xv6/JOS的原因是xv6没有完整的保护模式页机制和虚存管理机制，JOS不是传统的UNIX 单体内核架构，而是Exokerne内核架构，与当前OS教学的知识点有点远，在互联网上找了一圈，没有合适的。有人说为何不用Linux？其实Linux确实挺好的，只是对于首次学习OS原理的本科生要在短短一学期内搞懂Linux的部分实现细节，可能付出的代价会比较大，需要冒着挂掉其他课的风险。为此陈渝老师鼓励他带的硕士研究生王乃铮试试能否仿照xv6和linux自己鼓捣一个教学用的小OS，并用Ken Thompson和Linus在短短2~3个月分别开发了UNIX和Linux的故事来从精神上激励他。王乃铮同学看了xv6的代码，本着试试看的想法，就开始coding，并查看各种相关文档和资料，发现也只花了短短1个不到的时间就完成了支持lab1实验的ucore OS；为此信心大增，以月为单位又接连完成了支持lab2~lab8的ucore OS，前后大约花了8个月（这8个月还顺便完成了减轻体重和找女朋友的重要工作）。做完此事后，王乃铮同学离毕业只有3个时间了。有了之前OS开发的底子，他在3个月的时间内，完成了Linux kernel相关的硕士课题，顺利毕业，开始了他的创业生涯。

而陈渝老师鼓励和引导后续的学生继续着操作系统教学和科研的快乐之旅。目前发现ucore中有不少的bug（不过少于Linux的bug），陈渝老师准备带着学生再研究一些算法、方法和工具，能够在ucore运行前通过静态分析的方法发现其潜在的bug，而且希望能够在ucore漰溃后，找到引起bug的内核代码在哪里，并能分析出为何这个内核代码会导致ucore漰溃的因果链。希望这样能够减轻大家学习OS实验的负担。

## 附录A：相关资料

### OS基本概念和原理

 * OS课程资料     http://pan.baidu.com/s/1bncWxyv
 * OS MOOC公开课(原理部分)  http://www.topu.com/mooc/4100

### OS设计与实现细节

 * OS实验资料     http://pan.baidu.com/s/1i3vbdXV
 * OS实验代码     https://github.com/chyyuu/mooc_os_lab
 * OS MOOC公开课(实验部分)  http://www.topu.com/mooc/4100

### 动手实践OS
 * ucore step by step book  https://github.com/chyyuu/ucorebook
 * ucore step by step code  https://github.com/chyyuu/ucorebook_code
 * ucore plus    https://github.com/chyyuu/ucore_plus

### 开发维护人员

 * 陈渝 http://soft.cs.tsinghua.edu.cn/~chen  yuchen@tsinghua.edu.cn
 * 茅俊杰 eternal.n08@gmail.com

##　附录Ｂ：实验列表

### 1. lab1 ：bootloader启动操作系统
----------

####    启动/保护模式
   * proj1     : bootloader 能切换到x86-32保护模式且能够通过串口、并口、显示器来显示字符串
   * proj2   (<--proj1)     : bootloader能读磁盘且分析加载ELF格式的文件
   * proj3   (<--proj2)     : bootloader能ELF执行文件格式的 ucore toy OS，目前这个toy OS只能答应字符串

#### 显示函数调用栈
   * proj3.1  (<--proj3)     : ucore能输出函数调用栈信息(包括函数名和行号)，这样便于OS出错后分析问题

#### 响应外设中断
   * proj4  (<--proj3.1)   : ucore可处理从串口(COM1)、键盘、时钟外设来的中断

#### 支持用户态和内核态，以及系统调用机制
   * proj4.1  (<--proj4)     : 为了支持proj 4.1.1/2系统调用机制，ucore重新初始化并增加了用户态的代码段和数据段
   * proj4.1.1(<--proj4.1) : 用x86的中断机制实现系统调用机制
   * proj4.1.2(<--proj4.1) : 用x86的门（gate）机制实现系统调用机制
### 支持远程gdb调试  (附加部分，其实通过qemu的gdb remote server也可实现大部分功能)
   * proj4.2     (<--proj4.1)   : ucore增加 gdb remote server/stub，这样可以通过gdb远程调试ucore
   * proj4.3     (<--proj4.2)   : ucore支持硬件breakpoint和watchpoint，从而具有内部debugger功能

### 2. lab2 ：物理内存管理
----------

#### 物理内存管理
 * proj5    (<--proj4.3)   : ucore支持保护模式下的分页机制，并能够管理物理内存

#### OS教材上的连续物理内存分配算法
 * proj5.1     (<--proj5)     : 最佳适配算法
 * proj5.1.1   (<--proj5.1)   : 首次适配算法
 * proj5.1.2   (<--proj5.1)   : 最坏适配算法

#### 实际OS中的以页大小（4KB）为单位的连续物理内存分配算法
 * proj5.2     (<--proj5.1)   : 伙伴（buddy）分配算法

#### 实际OS中的小于页大小的连续物理内存分配算法
 * proj6       (<--proj5.2)   : SLAB内存分配算法

### 3. lab3 ：虚拟内存管理
-----------------------

#### 支持页访问错误异常的处理
 * proj7       (<--proj6)     : 能够有页访问错误异常的处理机制，提供了虚存管理（VMM）的框架

#### 提供swap机制，为能够实现各种页替换算法做好准备
 * proj8       (<--proj7)     : 实现swap in/out机制，并加入页替换算法的实现框架

#### 实现map/unmap机制，并提供dup, exit等函数，为后续进程管理（比如创建子进程等）做好准备
 * proj9       (<--proj8)     : 增加内核函数map, unmap, dup, exit等

#### 实现share memory机制，为后续进程间共享内存空间做好准备
 * proj9.1     (<--proj9)     : 实现 shmem_t内存结构，并完成香港函数，实现share memory

###3 实现COW机制，为高效创建子进程做好准备
 * proj9.2     (<--proj9.1)   : 实现支持高效进程复制的虚存核心功能Copy On Write（简称COW）

### 4. lab4 ：内核线程
-------------------------------

#### 创建内核线程，此时需要引入调度，进程上下文切换等机制
 * proj10      (<--proj9.2)   : 实现线程和进程管理的关键数据结构进程控制块（Process Control Block, 简称PCB），完成对内核线程的创建所需功能，并建立基本的调度机制，主要是体现能够切换两个内核线程。

### 5. lab5 ：用户进程
------------------------

#### 进程管理框架
 * proj10.1    (<--proj10)    : 实现用户进程管理框架，并完成与创建用户进程相关的内核函数（读ELF格式的文件、fork、execve），以及与调度进程相关的调度器

#### 与进程生命周期相关的系统调用
 * proj10.2    (<--proj10.1)  : 实现进程管理相关的系统调用 wait、kill、exit

#### 进程中的堆管理系统调用sys_brk
 * proj10.3    (<--proj10.2)  : 完成管理用户进程的内存堆（heap）的系统调用sys_brk

#### 与进程生命周期相关的涉及睡眠和唤醒的系统调用
 * proj10.4    (<--proj10.3)  : 完成用户进程调度相关的函数sleep，并增加timer的功能支持

#### 采用内核线程机制，能够根据系统状态更好地动态支持swap in/out虚存功能
 * proj11      (<--proj10.4)  : 用内核线程方式实现虚存的swap机制

#### 实现用户态的线程（基本原理与Linux的轻量级进程一致）
 * proj12      (<--proj11)    : 实现系统调用map、unmap和共享内存share memory，实现用户态线程机制;

### 6. lab6 ：处理器调度
-----------------------

#### OS教材上的调度算法
 * proj13      (<--proj12)    : 实现通用调度框架和简单的想来先服务（First Come First Serve，简称FCFS）调度算法
 * proj13.1    (<--proj13)    : 实现轮转（RoundRobin，简称RR）掉短算法
 * proj13.2    (<--proj13.1)  : 实现多级反馈队列（MultiLevel Feedback Queue，简称MLFQ）调度算法

### 7. lab7 : 同步互斥和进程间通信（IPC）
-----------------------

#### OS教材上的信号量机制
 * proj14      (<--proj13.2)  : 实现内核中的信号量（semaphore）机制

#### 用户态进程的信号量，需要考虑一些实际情况（比如一个获得信号量的进程漰溃了）
 * proj14.1    (<--proj14)    : 实现用于用户态进程/线程的信号量机制,
 * proj14.2    (<--proj14.1)  : 增加在信号量等待中的超时判断机制

#### 其他一些IPC机制，在一些实时OS中常见
 * proj15      (<--proj14.2)  : 实现事件（event ）IPC机制
 * proj16      (<--proj15)    : 实现邮箱（mailbox）IPC机制

####  OS教材上的管程（Monitor）和条件变量机制
 * proj16.1      (<--proj16)    : 实现管程和条件变量

### 8. lab8 : 文件系统
--------------------

#### 建立虚拟文件系统，把设备按文件來管理
 * proj17      (<--proj16)    : 实现vfs框架, file数据结构和相关操作，文件化各种输入输出外设(stdin, stdout, null)

#### 按照文件的方式实现一种UNIX中常见的IPC机制--管道（PIPE）
 * proj17.1    (<--proj17)    : 实现匿名管道（PIPE）和有名管道（FIFO）

#### 增加SFS （简单文件系统--sfs，并实现用户进程访问文件所涉及的函数）
 * proj18      (<--proj17.1)  : 在VFS上增加具体文件系统实例sfs 'simple filesystem'和对应的文件操作相关函数

#### 增加sfs中目录访问相关的函数
 * proj18.1    (<--proj18)    : 增加mkdir/link/rename/unlink (hard link)相关的系统调用和内核函数

#### 实现了通过exec加载存储在磁盘上的执行文件并创建/执行进程的功能

#### 实现exec功能
 * proj18.2    (<--proj18)    : add exec

#### 扩展exec功能，在加载运行应用程序能够带上执行参数
 * proj18.3    (<--proj18.2)  : add exec with arguments (at most 32)

#### 在上述ucore OS的支持上实现了shell（一个用户态的命令行交互执行程序）
 * proj19      (<--proj18.3)  : shell

## 版权信息
ucore OS是用于清华大学计算机系本科操作系统课程的OS教学试验内容。
ucore OS起源于MIT CSAIL PDOS课题组开发的xv6&jos、哈佛大学开发的
OS161教学操作系统、以及Linux-2.4内核。

ucore OS中包含的xv6&jos代码版权属于Frans Kaashoek, Robert Morris,
and Russ Cox，使用MIT License。ucore OS中包含的OS/161代码版权属于
David A. Holland。其他代码版权属于陈渝、王乃铮、向勇，并采用GPL License.
ucore OS相关的文档版权属于陈渝、向勇，并采用 Creative Commons
Attribution/Share-Alike (CC-BY-SA) License. **
