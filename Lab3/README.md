<<<<<<< HEAD
# JOS实验lab3内存管理

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习
+ 挑战

## 实验简介



## 练习部分



### Exercise 1


* 修改 `mem_init()` 来为 `Env` 结构体的数组`envs`，分配内存。
* 将`envs` 的物理内存设置为只读映射在页表中 `UENVS` 的位置，用户进程可以从这一数组读取数据。

```c++
// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
	memset(envs, 0, NENV * sizeof(struct Env));

//////////////////////////////////////////////////////////////////////
	// Map the 'envs' array read-only by the user at linear address UENVS
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);


```

在这里注意到一个细节，struct Env的大小为96个字节，NENV = 1024，算出实际分配的物理内存为98304Byte，即24个页，但是虚拟地址布局中 RO ENVS 区域大小是PTSIZE为4M（1024个页）。

### Exercise 2

#### env_init()

前面已经为进程描述符表分配了内存空间，现在要初始化这些描述符:

+ 将所有的描述符的进程id置位0
+ 状态置位free
+ 然后依次的放入到空闲列表中
+ 初始化的工作在循环开始前的memset就直接完成了

如在用户环境的分析中提到，env_init()主要负责初始化 `struct Env`的空闲链表，跟上一章的pages空闲链表类似，注意初始化顺序。

```
void
env_init(void)
{
    // Set up envs array
    // LAB 3: Your code here.
    for (int i = NENV-1; i >= 0; i--) {
        struct Env *e = &envs[i];
        e->env_id = 0;
        e->env_status = ENV_FREE;
        e->env_link = env_free_list;
        env_free_list = e;
    }   

    // Per-CPU part of the initialization
    env_init_percpu();
}
```

#### region_alloc()

这个函数将从va开始len字节的虚拟地址空间重新分配和映射到物理页中，更新页目录及二级页表。
**注意给定的va不一定是4096对齐的，解决办法是按提示所说将`va` rounddown向下4096对齐,`len` roundup向上4096对齐。**

```c++
// Allocate len bytes of physical memory for environment env,
// and map it at virtual address va in the environment's address space.
// Does not zero or otherwise initialize the mapped pages in any way.
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va + len, PGSIZE);
    for (; begin < end; begin += PGSIZE) 
    {
        struct Page *p = page_alloc(0);
        if (!p) 
        	panic("env region_alloc failed");
        page_insert(e->env_pgdir, p, begin, PTE_W | PTE_U);
    }   
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
```



### Exercise 3

### Exercise 4

### Exercise 5

### Exercise 6

### Exercise 7

### Exercise 8

### Exercise 9

### Exercise 10