# JOS实验lab2 内存管理

> **组员:    1711351 李汶蔚   1711308常欢 1711347 李瑞峰**

> 完成情况及分工：
>
> 详见wiki



## 零、实验要求

[Lab2实验要求](./Lab2实验要求.pdf)

## 一、实验简介

本次实验包含5个练习，6个问题以及4个挑战任务，实验内容主要分为两部分：

##### (一)物理页面管理

**操作系统必须知道物理RAM的哪些部分是空闲的，哪些部分正在被使用。JOS以页（page)为单位管理PC的物理内存，从而可以使用MMU映射和保护每一片分配的内存。**

*任务：完成物理页分配器。它用于保存哪些页面是空闲的，在数据的组织上，由struct Page对象构成的链表，每个Page结构都对应一个物理页。在完成虚拟内存实验之前，编写物理页分配器。*

##### (二)虚拟内存

**在x86术语中，虚拟地址由段选择器和段内的偏移组成。线性地址是在段转换之后，页转换之前的地址。物理地址是在段和页转换之后最终获得的最终地址，也就是最终在硬件总线上最后出现在RAM中的物理地址。**

*任务：为整个JOS设置虚拟内存布局，映射前256MB物理内存到虚拟地址0xf0000000处，并映射虚拟内存的其他区域。*

## 二、实验过程

#### Exercise 1：编写物理页分配器

```c++
在文件kern/pmap.c中，必须实现以下函数的代码（可能按照给定的顺序）。

boot_alloc()
mem_init()（仅完成调用check_page_free_list(1) 之前的部分）
page_init()
page_alloc()
page_free()

check_page_free_list()和check_page_alloc()会测试你的物理页面分配器。你应该启动JOS并查看check_page_alloc() 是否报告成功。修改代码，并确定能够通过它的测试。你可以添加自己的assert()来验证你的假设是否正确。
```

首先，查看pmap.c文件，发现其包含了两个很重要的头文件，分别是：`#include <inc/mmu.h>`和`#include <kern/pmap.h>`，对这两个文件进行宏观上的认识：

##### (一) <inc/mmu.h>

该文件中包含三部分：

**第一部分是页机制中32位地址的划分，最高10位作为PDX（页目录下标），接着10位作为PTX（页表下标），低10位是页偏移。**

```c++
// +--------10------+-------10-------+---------12----------+
// | Page Directory |   Page Table   | Offset within Page  |
// |      Index     |      Index     |                     |
// +----------------+----------------+---------------------+
//  \--- PDX(la) --/ \--- PTX(la) --/ \---- PGOFF(la) ----/
//  \---------- PGNUM(la) ----------/
```

**并且定义了一些常量，包括获取各个部分的偏移量、页大小、页表项的各个标志位、以及页缺失等常量。**

**第二部分是定义与段机制有关的数据结构与常量，如struct Segdesc。**

**第三部分是定义了Trap中断用到的数据结构和常量，如struct Taskstate、struct Gatedesc、struct Pseudodesc等。**

##### (二) <kern/pmap.h>

在该文件中，又引入了一个很重要的文件`#include <inc/memlayout.h>`	。

在**memlayout.h**中展示了Jos内存的存储情况即内存的布局，并定义了每个内存段的起始地址和大小，将内存分成了几个部分。

**PGSIZE：4096字节（页大小）； PTSIZE：1024 x 4096(1024个页)**;

**定义了描述物理页的数据结构：**

```c++
struct Page {
	// Next page on the free list.
	struct Page *pp_link;

	// pp_ref is the count of pointers (usually in page table entries)
	// to this page, for pages allocated using page_alloc.
	// Pages allocated at boot time using pmap.c's
	// boot_alloc do not have valid reference count fields.

	uint16_t pp_ref;
};
```

<hr>

**pmap.h中除了定义了pmap.c中要完成的那几个代码之外，还定义了几个重要的内联函数：**

```c++
extern char bootstacktop[], bootstack[];

extern struct Page *pages;
extern size_t npages;

extern pde_t *kern_pgdir;

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT; //PGSHIFT = 12 页内偏移 2^12 = 4096字节
}
```

```c++
static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
}
```

```c++
static inline void* //a physical address and returns the corresponding kernel virtual address.
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
```

##### (三）练习解答

**至此，我们知道内存管理分配需要的数据结构和函数已定义完成，我们分析pmap.c这个文件，并完成练习一，代码如下。**

```c++
//pmap.c
// These variables are set by i386_detect_memory()
size_t npages;			// Amount of physical memory (in pages)
static size_t npages_basemem;	// Amount of base memory (in pages)

// These variables are set in mem_init()
pde_t *kern_pgdir;		// Kernel's initial page directory
struct Page *pages;		// Physical page state array
static struct Page *page_free_list;	// Free list of physical pages
```

1. boot_alloc()

```c++
// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
```

2. mem_init()

```

```

3. page_init()

```

```

4. page_alloc()

```

```

4. page_free()

```

```



## 三、问题讨论



