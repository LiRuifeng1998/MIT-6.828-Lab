# JOS实验lab3内存管理

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习
+ 挑战

## 实验简介

1. Enc结构体

   ```c++
   struct Env {
   
     struct Trapframe env_tf;  // Saved registers
   
     struct Env *env_link;    // Next free Env
   
     envid_t env_id;     // Unique environment identifier
   
     envid_t env_parent_id;   // env_id of this env's parent
   
     enum EnvType env_type;   // Indicates special system environments
   
     unsigned env_status;    // Status of the environment
   
     uint32_t env_runs;   // Number of times environment has run
   
     // Address space
   
     pde_t *env_pgdir;    // Kernel virtual address of page dir
   
   };
   ```

2. 

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

**注意：**反向初始化，到最后就保证env_free_list指向第一个env，而且比正向初始化操作简便

```c++
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

#### env_setup_vm()

作用是为当前的进程分配一个页，用来存放页表目录，同时将内核部分的内存的映射完成

+ Hint中提到，所有的进程，不论是内核还是用户，在虚地址UTOP之上的内容都是一样的，所以直接copy即可。
+ 因为UVTP是一个特例，所以单独对UVTP进行设置。

```c++
static int
env_setup_vm(struct Env *e)
{
    int i;
    struct PageInfo *p = NULL;

    // Allocate a page for the page directory
    if (!(p = page_alloc(ALLOC_ZERO)))
        return -E_NO_MEM;

    // Now, set e->env_pgdir and initialize the page directory.
    // LAB 3: Your code here.
    p->pp_ref++;
    e->env_pgdir = (pde_t *)page2kva(p);
    memcpy(e->env_pgdir, kern_pgdir, PGSIZE);

    // UVPT maps the env's own page table read-only.
    // Permissions: kernel R, user R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

    return 0;
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



#### load_icode()

加载用户程序二进制代码。该函数会设置进程的tf_eip值为 elf->e_entry，并分配映射用户栈内存。注意，在调用 `region_alloc` 分配映射内存前，需要先设置cr3寄存器内容为进程的页目录物理地址，设置完成后再设回 kern_pgdir的物理地址。

```
static void
load_icode(struct Env *e, uint8_t *binary)
{
    struct Elf *env_elf;
    struct Proghdr *ph, *eph;
    env_elf = (struct Elf*)binary;
    ph = (struct Proghdr*)((uint8_t*)(env_elf) + env_elf->e_phoff);
    eph = ph + env_elf->e_phnum;

    lcr3(PADDR(e->env_pgdir));

    for (; ph < eph; ph++) {
        if(ph->p_type == ELF_PROG_LOAD) {
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
            memcpy((void*)ph->p_va, (void *)(binary+ph->p_offset), ph->p_filesz);
            memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz-ph->p_filesz);
        }
    }

    e->env_tf.tf_eip = env_elf->e_entry;
    lcr3(PADDR(kern_pgdir));

    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.
    region_alloc(e, (void *)(USTACKTOP-PGSIZE), PGSIZE);
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