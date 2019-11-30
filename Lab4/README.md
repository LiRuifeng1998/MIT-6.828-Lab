# Lab 4: Preemptive Multitasking / 抢占式多任务处理

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习

## 实验简介

## 实验概括

## 练习部分

### Exercise 1

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

## 问题1

Q：为什么mpentry.S要用到MPBOOTPHYS，而boot.S不需要？

 这是因为mpentry.S代码mpentry_start, mpentry_end的地址都在KERNBASE(0xf0000000）之上，实模式无法寻址，而我们将mpentry.S加载到了0x7000处，所以需要通过MPBOOTPHYS来寻址。而boot.S加载的位置本身就是实模式可寻址的低地址，所以不用额外转换。

### Exercise 3：

<hr>

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

## Exercize 4

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

## Exercize 5

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
	unlock_kernel();
}
```



## 遇到的问题