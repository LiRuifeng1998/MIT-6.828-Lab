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


### Exercise 2：应用处理器（AP）引导程序

<hr>

```c++
//在启动 AP 之前，BSP 应当首先收集多处理器系统的信息，例如，CPU总数，他们的 APIC ID，和 LAPIC单元 的 MMIO 地址。
// `boot_aps()` 函数驱动 AP 的引导过程。 AP 从实模式开始启动，就像 在 `boot/boot.S` 中的 bootloader 一样。所以 `boot_aps()` 将 AP 的入口代码 ( `kern/mpentry.S` ) 拷贝到一个实模式中能够访问到的内存地址。

size_t i, mp_page = PGNUM(MPENTRY_PADDR);
for (i = 1; i < npages_basemem; i++) 
{
  if (i == mp_page) continue;
  		pages[i].pp_ref=1;
}
```

#### 问题1

Q：为什么mpentry.S要用到MPBOOTPHYS，而boot.S不需要？

 这是因为mpentry.S代码mpentry_start, mpentry_end的地址都在KERNBASE(0xf0000000）之上，实模式无法寻址，而我们将mpentry.S加载到了0x7000处，所以需要通过MPBOOTPHYS来寻址。而boot.S加载的位置本身就是实模式可寻址的低地址，所以不用额外转换。

### Exercise 3：

---


修改 `mem_mp_init()`为每个cpu分配内核栈。CPU内核栈之间有空出KSTKGAP(32KB)，其目的是为了避免一个CPU的内核栈覆盖另外一个CPU的内核栈，空出来这部分可以在栈溢出时报错。每个堆栈的大小都是 `KSTKSIZE` 字节，加上 `KSTKGAP` 字节没有被映射的 守护页 。

```c++
static void mem_init_mp(void)
{
    int i;
  for (i = 0; i < NCPU; i++) 
	{
        int kstacktop_i = KSTACKTOP - KSTKSIZE - i * (KSTKSIZE + KSTKGAP);
        boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
  }
}
```

### Exercize 4

---

修改`trap_init_percpu()`，完成每个CPU的TSS初始化。设置ts_esp0和ts_ss0。

```c++
// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
void
trap_init_percpu(void)
{
    int cpu_id = thiscpu->cpu_id;
    struct Taskstate *this_ts = &thiscpu->cpu_ts;
    this_ts->ts_esp0 = KSTACKTOP - cpu_id * (KSTKSIZE + KSTKGAP);
    this_ts->ts_ss0 = GD_KD;
    this_ts->ts_iomb = sizeof(struct Taskstate);
		//在lab3基础上修改以上代码
    gdt[(GD_TSS0 >> 3) + cpu_id] = SEG16(STS_T32A, (uint32_t) (this_ts),
                    sizeof(struct Taskstate) - 1, 0); 
    gdt[(GD_TSS0 >> 3) + cpu_id].sd_s = 0;
    ltr(GD_TSS0 + (cpu_id << 3));
    lidt(&idt_pd);
}
```

### Exercize 5

目前我们的代码在 `mp_main()` 初始化完 AP 就不再继续执行了。在允许 AP 继续运行之前，我们需要首先提到当多个 CPU 同时运行内核代码时造成的 *竞争状态* (race condition) ，为了解决它，最简单的办法是使用一个 *全局内核锁* (big kernel lock)。这个 big kernel lock 是唯一的一个全局锁，每当有进程进入内核模式的时候，应当首先获得它，当进程回到用户模式的时候，释放它。在这一模式中，用户模式的进程可以并发地运行在任何可用的 CPU 中，但是最多只有一个进程可以运行在内核模式下。其他试图进入内核模式的进程必须等待。

- `i386_init()` 中，在 BSP 唤醒其他 CPU 之前获得内核锁。
- `mp_main()` 中，在初始化完 AP 后获得内核锁，接着调用 `sched_yield()` 来开始在这个 AP 上运行进程。
- `trap()` 中，从用户模式陷入(trap into)内核模式之前获得锁。你可以通过检查 `tf_cs` 的低位判断这一 trap 发生在用户模式还是内核模式（译注：Lab 3 中曾经使用过这一检查）。
- env_run() 中，恰好在 **回到用户进程之前** 释放内核锁。不要太早或太晚做这件事，否则可能会出现竞争或死锁。

```c++

void i386_init(void)
{
	...
	// Acquire the big kernel lock before waking up APs
	// Your code here:
	lock_kernel();
	// Starting non-boot CPUs
	boot_aps();
	...
}
void mp_main(void)
{
	...
	// Your code here:
	lock_kernel();
  sched_yield();
	// Remove this after you finish Exercise 4
	//for (;;);
	...
}

void trap(struct Trapframe *tf)
{
	...
	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
		...
		}
}
void env_run(struct Env *e)
{
  // LAB 3: Your code here.
	if(curenv != NULL && curenv != e)
	{
		curenv->env_status = ENV_RUNNABLE;
	}
	if(curenv != e)
	{
		curenv = e;
		curenv->env_status = ENV_RUNNING;
		curenv->env_runs++;
		lcr3(PADDR(curenv->env_pgdir));
	}
	env_pop_tf(&curenv->env_tf);
	unlock_kernel();//释放内核锁，该函数将使用iret指令，从内核返回用户态。
}
```

#### 问题 2

为什么有了大内核锁后还要给每个CPU分配一个内核栈？ 

这是因为虽然大内核锁限制了多个进程同时执行内核代码，但是在陷入trap()之前，CPU硬件已经自动压栈了SS, ESP, EFLAGS, CS, EIP等寄存器内容，而且在`trapentry.S`中也压入了错误码和中断号到内核栈中，所以不同CPU必须分开内核栈，否则多个CPU同时陷入内核时会破坏栈结构，此时都还没有进入到trap()的加大内核锁位置。

#### Exercize 6

- `kern/sched.c` 中的 `sched_yied()` 函数负责挑选一个进程运行。它从刚刚在运行的进程开始，按顺序循环搜索 `envs[]` 数组（如果从来没有运行过进程，那么就从数组起点开始搜索），选择它遇到的第一个处于 `ENV_RUNNABLE`（参考 `inc/env.h`）状态的进程，并调用 `env_run()` 来运行它。
- `sched_yield()` 绝不应当在两个CPU上同时运行同一进程。它可以分辨出一个进程正在其他CPU（或者就在当前CPU）上运行，因为这样的进程处于 `ENV_RUNNING` 状态。
- 用户进程可以调用它来触发内核的 `sched_yield()` 方法，自愿放弃 CPU，给其他进程运行。

```c++
// 修改kern/sched.c中调度函数实现
void
sched_yield(void)
{
	struct Env *idle;

	idle = curenv;
	int start_envid = idle ? ENVX(idle->env_id)+1 : 0; //从当前Env结构的后一个开始

	for (int i = 0; i < NENV; i++) { ////遍历所有Env结构
		int j = (start_envid + i) % NENV;
		if (envs[j].env_status == ENV_RUNNABLE) {
			env_run(&envs[j]);
		}
	}
	//no envs are runnable, but the environment previously
	// running on this CPU is still ENV_RUNNING
	if (idle && idle->env_status == ENV_RUNNING) { //这是必须的，假设当前只有一个Env，如果没有这个判断，那么这个CPU将会停机
		env_run(idle);
	}

	// sched_halt never returns
	sched_halt();
}
//修改kern/syscall.c
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  ...
  case SYS_yield:
               sys_yield();
               return 0;
  ...
}
//修改kern/init.c
void
i386_init(void)
{
  ...	//添加三个新的进程，运行 user/yield.c
       ENV_CREATE(user_yield, ENV_TYPE_USER);
       ENV_CREATE(user_yield, ENV_TYPE_USER);
       ENV_CREATE(user_yield, ENV_TYPE_USER);
  ...
}
```



## 遇到的问题

