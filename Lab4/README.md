# Lab 4: Preemptive Multitasking / 抢占式多任务处理

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习

## 实验概括


## 实验知识总结

### 1 "symmetric multiprocessing" (SMP)

"symmetric multiprocessing" (SMP)，这是一种所有CPU共享系统资源的多处理器模式。在启动阶段这些CPU将被分为两类：

1. 启动CPU（BSP）：负责初始化系统，启动操作系统。

2. 应用CPU（AP）：操作系统启动后由BSP激活：

   哪一个CPU是BSP由硬件和BISO决定，到目前位置所有JOS代码都运行在BSP上。
   在SMP系统中，每个CPU都有一个对应的local APIC（LAPIC），负责传递中断。CPU通过内存映射IO(MMIO)访问它对应的APIC，这样就能通过访问内存达到访问设备寄存器的目的。LAPIC从物理地址0xFE000000开始，JOS将通过MMIOBASE虚拟地址访问该物理地址。



### 2 CPUInfo

```c++
struct CpuInfo {
    uint8_t cpu_id;                 // Local APIC ID; index into cpus[] below
    volatile unsigned cpu_status;   // The status of the CPU
    struct Env *cpu_env;            // The currently-running environment.
    struct Taskstate cpu_ts;        // Used by x86 to find stack for interrupt
};
```

每个CPU如下信息是当前CPU私有的：

1. 内核栈：内核代码中的数组`percpu_kstacks[NCPU][KSTKSIZE]`为每个CPU都保留了KSTKSIZE大小的内核栈。从内核线性地址空间看CPU 0的栈从KSTACKTOP开始，CPU 1的内核栈将从CPU 0栈后面KSTKGAP字节处开始，以此类推，参见inc/memlayout.h。
2. TSS和TSS描述符：每个CPU都需要单独的TSS和TSS描述符来指定该CPU对应的内核栈。
3. 进程结构指针：每个CPU都会独立运行一个进程的代码，所以需要Env指针。
4. 系统寄存器：比如cr3, gdt, ltr这些寄存器都是每个CPU私有的，每个CPU都需要单独设置。

**envs和CpuInfo关系如下图**

![](./pic/cpuInfo.png)





## 练习部分

### Exercise 1

>实现在 `kern/pmap.c` 中的 `mmio_map_region` 方法。
>
>你可以看看 `kern/lapic.c` 中 `lapic_init` 的开头部分，了解一下它是如何被调用的。你还需要完成接下来的练习，你的 `mmio_map_region` 才能够正常运行。

```c++
void *
mmio_map_region(physaddr_t pa, size_t size)
{
    // Where to start the next region.  Initially, this is the
    // beginning of the MMIO region.  Because this is static, its
    // value will be preserved between calls to mmio_map_region
    // (just like nextfree in boot_alloc).
    static uintptr_t base = MMIOBASE;

    // Reserve size bytes of virtual memory starting at base and
    // map physical pages [pa,pa+size) to virtual addresses
    // [base,base+size).  Since this is device memory and not
    // regular DRAM, you'll have to tell the CPU that it isn't
    // safe to cache access to this memory.  Luckily, the page
    // tables provide bits for this purpose; simply create the
    // mapping with PTE_PCD|PTE_PWT (cache-disable and
    // write-through) in addition to PTE_W.  (If you're interested
    // in more details on this, see section 10.5 of IA32 volume
    // 3A.)
    //
    // Be sure to round size up to a multiple of PGSIZE and to
    // handle if this reservation would overflow MMIOLIM (it's
    // okay to simply panic if this happens).
    //
    // Hint: The staff solution uses boot_map_region.
    //
    // Your code here:
    size = ROUNDUP(pa+size, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    size -= pa;//做一个对齐
    if (base+size >= MMIOLIM) panic("not enough memory");
    boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
    base += size;
    return (void*) (base - size);
}
```

​		在SMP系统中，每个CPU都有一个对应的local APIC（LAPIC），负责传递中断。CPU通过内存映射IO(MMIO)访问它对应的APIC，这样就能通过访问内存达到访问设备寄存器的目的。LAPIC从物理地址0xFE000000开始，JOS将通过MMIOBASE虚拟地址访问该物理地址。

​		`boot_map_region`函数：

> Map [va, va+size) of virtual address space to physical [pa, pa+size)
>
> in the page table rooted at pgdir.  Size is a multiple of PGSIZE.
>
> Use permission bits perm|PTE_P for the entries.

​		该函数作用：给定物理地址和size，将pa-pa+size映射到MMIOBASE-MMIOBASE+size上，设置权限位告诉CPU这块内存不应该cache，是不安全的。

### Exercise 2



### Exercise 3



### Exercise 4



### Exercise 5

### Exercise 6

### Exercise 7

### Exercise 8

### Exercise 9
### Exercise 10
### Exercise 11
### Exercise 12
### Exercise 13
### Exercise 14
### Exercise 15



## 遇到的问题

