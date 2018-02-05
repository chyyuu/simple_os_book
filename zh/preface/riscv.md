# RISC-V硬件架构

通用CPU一般能够在硬件上支持内存空间的隔离，使得多个程序在各自独立的内存空间中并发执行。这种硬件机制即支持用户特权级和内核特权级。应用程序运行在用户特权级，这样应用不能执行特权指令，且不能破坏操作系统内核的数据和操作系统执行过程。而操作系统内核运行在内核特权级，可以访问特权指令，并管理和控制应用程序，硬件外设等。所以对于操作系统而言，需要CPU硬件至少支持用户特权级和内核特权级（控制隔离），以及内存空间隔离（数据隔离）。

RISC-V是发源于Berkeley的开源instruction set architecture (ISA)。在继续阅读前，对RISCV指令集和架构特别感兴趣的同学可仔细阅读RISC-V的Specifications。当前用户态指令集规范的版本为2.2，特权态指令集规范的版本为1.10。

* [User-Level ISA Specification v2.2](https://riscv.org/specifications/)
* [Draft Privileged ISA Specification v1.10](https://riscv.org/specifications/privileged-isa)

## Modular ISA

RISC-V ISA是模块化的，它由一个基本指令集和一些扩展指令集组成

* Base integer ISAs
    - RV32I
    - RV64I
    - RV128I
* Standard extensions
    - M: Integer **M**ultiply
    - A: **A**tomic Memory Operations
    - F: Single-percison **F**loating-point
    - D: **D**ouble-precision Floating-point
    - G: IMAFD, **G**eneral Purpose ISA

举例来说，`RV32IMA`表示支持基本整数操作和原子操作的32位RISC-V指令集。对于一般在用户态执行的应用程序，只需要上述用户态指令集就基本足够了。但如果是象操作系统这样的软件，需要控制整个计算机硬件，则只使用用户态指令集是不够的，还需要在处于内核特权级的CPU状态下执行特权指令集。

## Privileged ISA

### Software Stacks

RISC-V在设计时就考虑了硬件虚拟化的需求，三种典型RISC-V系统的结构如下

![software-stacks](figures/software-stacks.png)

上图中各个英文缩写对应的全称如下

* ABI: Application Binary Interface
* AEE: Application Execution Environment
* SBI: Supervisor Binary Interface
* SEE: Supervisor Execution Environment
* HBI: Hypervisor Binary Interface
* HEE: Hypervisor Execution Environment

RISC-V通过各层之间的Binary Interface实现了对下一层的抽象，方便了虚拟机的实现以及OS在不同RISC-V架构间的移植。采用了图中第二种结构，[bbl](https://github.com/riscv/riscv-pk)在其中充当了SEE的角色。

### Privilege Levels

RISC-V共有4种不同的特权级，与x86不同的是，RISC-V中特权级对应数字越小，权限越低

| Level | Encoding |       Name       | Abbreviation |
| :---: | :------: | :--------------: | :----------: |
|   0   |    00    | User/Application |      U       |
|   1   |    01    |    Supervisor    |      S       |
|   2   |    10    |    Hypervisor    |      H       |
|   3   |    11    |     Machine      |      M       |

一个RISC-V的实现并不要求同时支持这四种特权级，可接受的特权级组合如下

| Number of levels | Supported Modes | Intended Usage                           |
| :--------------: | --------------- | ---------------------------------------- |
|        1         | M               | Simple embedded systems                  |
|        2         | M, U            | Secure embedded systems                  |
|        3         | M, S, U         | Systems running Unix-like operating systems |
|        4         | M, H, S, U      | Systems running Type-1 hypervisors       |

目前官方的[Spike](https://github.com/riscv/riscv-isa-sim)模拟器只部分实现了3个特权级。

### Control and Status Registers

RISC-V中各个特权级都有单独的Control and Status Registers (CSRs)，其中应当注意的有以下几个

| Name     | Description                              |
| -------- | ---------------------------------------- |
| sstatus  | Supervisor status register               |
| sie      | Supervisor interrupt-enable register     |
| stvec    | Supervisor trap handler base address     |
| sscratch | Scratch register for supervisor trap handlers |
| sepc     | Supervisor exception program counter     |
| scause   | Supervisor trap cause                    |
| sbadaddr | Supervisor bad address                   |
| sip      | Supervisor interrupt pending             |
| sptbr    | Page-table base register                 |
| mstatus  | Machine status register                  |
| medeleg  | Machine exception delegation register    |
| mideleg  | Machine interrupt delegation register    |
| mie      | Machine interrupt-enable register        |
| mtvec    | Machine trap-handler base address        |
| mscratch | Scratch register for machine trap handlers |
| mepc     | Machine exception program counter        |
| mcause   | Machine trap cause                       |
| mbadaddr | Machine bad address                      |
| mip      | Machine interrupt pending                |

在继续阅读前，读者应当查阅[Privileged Spec 1.9.1](https://riscv.org/specifications/privileged-isa)以熟悉以上CSR的功能和用途。

#### CSR Instructions

RISC-V ISA中提供了一些修改CSR的原子操作，下面介绍之后常用到的`csrrw`指令

```nasm
# Atomic Read & Write Bit
cssrw rd, csr, rs
```

语义上等价的C++函数如下

```cpp
void cssrw(unsigned int& rd, unsigned int& csr, unsigned int& rs) {
  unsigned int tmp = rs;
  rd = csr;
  csr = tmp;
}
```

几种有趣的用法如下

```nasm
# csr = rs
cssrw x0, csr, rs

# csr = 0
cssrw x0, csr, x0

# rd = csr, csr = 0
cssrw rd, csr, x0

# swap rd and csr
cssrw rd, csr, rd
```
