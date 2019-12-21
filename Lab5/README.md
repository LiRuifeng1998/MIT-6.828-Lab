# Lab 5: File system, Spawn and Shell / 文件系统，Spawn 和 Shell

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习

## 实验概括

本lab将实现JOS的文件系统，只要包括如下四部分：

1. 引入一个**文件系统进程（FS进程）**的特殊进程，该进程提供文件操作的接口。
2. **建立RPC机制**，客户端进程向FS进程发送请求，FS进程真正执行文件操作，并将数据返回给客户端进程。
3. 更高级的抽象，引入**文件描述符**。通过文件描述符这一层抽象就可以将**控制台，pipe，普通文件**，统统按照文件来对待。（文件描述符和pipe实现原理）
4. 支持从磁盘**加载程序**并运行。


## 实验知识总结

### 1. 文件元数据

扇区是磁盘的物理属性，通常一个扇区大小为512字节，而数据块则是操作系统使用磁盘的一个逻辑属性，一个块大小通常是扇s区的整数倍，在JOS中一个块大小为4KB，跟我们物理内存的页大小一致。

JOS使用同一个 File 结构存储了磁盘和内存中的文件元数据。File结构既能代表文件也能代表目录，由type字段区分，文件系统以相同的方式管理文件和目录，只是目录文件的内容是一系列File结构，这些File结构描述了在该目录下的文件或者子目录。
超级块中包含一个File结构，代表文件系统的根目录。

```c++

struct File {
	char f_name[MAXNAMELEN];	// filename
	off_t f_size;			// file size in bytes
	uint32_t f_type;		// file type

	// Block pointers.
	// A block is allocated iff its value is != 0.
	uint32_t f_direct[NDIRECT];	// direct blocks
	uint32_t f_indirect;		// indirect block

	// Pad out to 256 bytes; must do arithmetic in case we're compiling
	// fsformat on a 64-bit machine.
	uint8_t f_pad[256 - MAXNAMELEN - 8 - 4*NDIRECT - 4];
} __attribute__((packed));	// re
```

struct File中的f_direct数组存储了前10个数据块的块号，这10个数据块是直接块。每个块为4KB，所以直接块可以存储40KB内的小文件。而对于大文件，File中还支持一个间接块，间接块可以存储 4096/4 = 1024 个块号，即JOS中最大可以存储1034个块大小的文件，即最大支持4MB左右的文件。在Linux中，还有二级间接块以及三级间接块等，用于存储更大的文件。

![](./pic/file.png)

```c++
//super block 1号块
struct Super {
	uint32_t s_magic;		// Magic number: FS_MAGIC
	uint32_t s_nblocks;		// Total number of blocks on disk
	struct File s_root;		// Root directory node
};

```



### 2 . 块缓存

JOS文件系统将 0x10000000(DISKMAP) 到 0xD0000000(DISKMAP+DISKMAX）这个区间的地址空间映射到磁盘，即JOS可以处理3GB的磁盘文件。如0x1000000 映射到数据块0，0x10001000 映射到数据库1。块缓存代码在 `fs/bc.c` 中，其中 diskaddr 函数可以完成数据块号到虚拟地址的转换。

JOS采用的是`demand paging`，即访问对应的磁盘块发生了页错误时才分配物理页。

### 3 . 块位图

在fs_init设置bitmap指针后，可以认为bitmap就是一个位数组，每个块占据一位。可以通过 block_is_free 检查块位图中的对应块是否空闲，如果为1表示空闲，为0已经使用。JOS中第0，1，2块分别给bootloader，superblock以及bitmap使用了。此外，因为在文件系统中加入了user目录和fs目录的文件，导致JOS文件系统一共用掉了0-110这111个文件块，下一个空闲文件块从111开始。

### 4. 文件操作

在 fs/fs.c 中有很多文件操作相关的函数，这里的主要几个结构体要说明下：

- struct File 用于存储文件元数据，前面提到过。
- struct Fd 用于文件模拟层，类似文件描述符，如文件ID，文件打开模式，文件偏移都存储在Fd中。一个进程同时最多打开 MAXFD(32) 个文件。
- 文件系统进程还维护了一个打开文件的描述符表，即opentab数组，数组元素为 struct OpenFile。OpenFile结构体用于存储打开文件信息，包括文件ID，struct File以及struct Fd。JOS同时打开的文件数一共为 MAXOPEN(1024) 个。

```c++
 struct OpenFile {                                                              
     uint32_t o_fileid;  // file id                                             
     struct File *o_file;    // mapped descriptor for open file                 
     int o_mode;     // open mode                                               
     struct Fd *o_fd;    // Fd page                                             
 };    
 
 struct Fd {
     int fd_dev_id;
     off_t fd_offset;
     int fd_omode;
     union {
         // File server files
         struct FdFile fd_file;
     };  
 }; 
```



## 练习部分

#### Exercise 1

> `i386_init` 通过为进程创建函数，`env_create`， 传递 `ENV_TYPE_FS` 类型来标记这个进程是文件系统进程。修改 `env.c` 的 `env_create` 函数，使它给予文件系统进程 I/O 特权，而不要给其他任何进程文件系统特权。
>
> 确信你能够不触发一般保护错(General Protection Fault)的情况下启动文件进程。现在，你应该能够在 `make grade` 中通过 `fs i/o` 这一项了。

```c++
void
env_create(uint8_t *binary, enum EnvType type)
{
	// LAB 3: Your code here.

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	struct Env* env;
	env_alloc(&env, 0);
	if (type == ENV_TYPE_FS) 
	{
        env->env_tf.tf_eflags |= FL_IOPL_MASK;
    }
	env->env_parent_id = 0;
    env->env_type = type;
	load_icode(env, binary);
}
```

**问题**

> 除此之外，你还需要做其他别的事情来确保在切换进程的时候这个 I/O 特权设置能够被正确地保留下来吗？为什么？

不需要，因为每个进程都有自己的Trampframe，不会相互影响。

#### Exercise 2

> 实现在 `fs/bc.c` 的 `bc_pgfault` 和 `flush_block` 方法。`bc_pgfault` 是一个缺页处理函数，就像是在上次实验中，你所写的 copy-on-write 的 fork 一样，除了它的工作是在缺页时从磁盘中将页读入内存。当完成这一部分时，不要忘了：1. `addr` 可能并没有和块边界对齐，2. `ide_read` 方法操作的是扇区，而不是块。

缺页时，分配一个物理页，从磁盘中读取缺失的页到新分配的页。

ide_read() 的单位是扇区，不是磁盘块，通过 outb 指令设置读取的扇区数，通过insl指令读取磁盘数据到对应的虚拟地址addr处。

bc_pgfault 中分配了一页物理页，然后从磁盘中读取出错的addr那一块数据(8个扇区）到分配的物理页中，然后清除分配页的dirty标记，最后调用 block_is_free 检查对应磁盘块确保磁盘块已经分配

```c++
	// Allocate a page in the disk map region, read the contents
	// of the block from the disk into that page.
	...
	  addr = ROUNDDOWN(addr, PGSIZE);//页对齐
    sys_page_alloc(0, addr, PTE_W|PTE_U|PTE_P);
    if ((r = ide_read(blockno * BLKSECTS, addr, BLKSECTS)) < 0)//BLKSECTS = 4096/512 = 8个扇区
        panic("ide_read: %e", r);
   ...
```

flush_block()函数用于在写入磁盘数据到块缓存后，调用 ide_write() 写入块缓存数据到磁盘中。写入完成后，也要通过 sys_page_map() 清除块缓存的 dirty 标记(每次写入物理页的时候，处理器会自动标记该页为 dirty，即设置PTE_D标记)。

```c++
 // LAB 5: Your code here.
    addr = ROUNDDOWN(addr, PGSIZE);
    if (!va_is_mapped(addr) || !va_is_dirty(addr)) {        //如果addr还没有映射过或者该页载入到内存后还没有被写过，不用做任何事
        return;
    }
		int r;
    if ((r = ide_write(blockno * BLKSECTS, addr, BLKSECTS)) < 0) {      //写回到磁盘
        panic("in flush_block, ide_write(): %e", r);
    }
    if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)  //清空PTE_D位
        panic("in bc_pgfault, sys_page_map: %e", r);
```

#### Exercise 3

> 将 `free_block` 作为模型，实现 `alloc_block` 方法。这个方法应该在位图中找到一个空闲的磁盘块，将其标记为占用，并返回块的块号。When you allocate a block, you should immediately flush the changed bitmap block to disk with flush_block, to help file system consistency. / 每当你分配一个块时，你应该立即用 `flush_block` 将改变的位图块刷回磁盘，以保证文件系统的连续性。

diskaddr得到指定块的虚拟地址。

```c++
// Return the virtual address of this disk block.
void*
diskaddr(uint32_t blockno)
{
	if (blockno == 0 || (super && blockno >= super->s_nblocks))
		panic("bad block number %08x in diskaddr", blockno);
	return (char*) (DISKMAP + blockno * BLKSIZE);
}
```

NINDIRECT为间接块的块号，共1024个块指针。

```c++
... 
		uint32_t bmpblock_start = 2;
    for (uint32_t blockno = 0; blockno < super->s_nblocks; blockno++)
    {
        if (block_is_free(blockno)) 
        {                   //搜索free的block
            bitmap[blockno / 32] &= ~(1 << (blockno % 32));     //标记为已使用
            flush_block(diskaddr(bmpblock_start + (blockno / 32) / NINDIRECT)); //将刚刚修改的bitmap block写到磁盘中
            return blockno;
        }
    }
...
```



### File Operations

#### Exercise 4

> 实现 `file_block_walk` 和 `file_get_block`。`file_block_walk` 将文件内部的块偏移量对应于 `struct File` 中的相应的块或者间接块，非常像是 `pgdir_walk` 这个函数对页表做的那样。`file_get_block` 更进一步，将其对应于实际的磁盘块，如果有必要就分配个新的。

基本的文件系统操作：

1. `file_block_walk(struct File *f, uint32_t filebno, uint32_t **ppdiskbno, bool alloc)`：查找f指向文件结构的第filebno个block的存储地址，保存到ppdiskbno中。如果f->f_indirect还没有分配，且alloc为真，那么将分配新的block作为该文件的f->f_indirect。类比页表管理的pgdir_walk()。

```c++
 // LAB 5: Your code here.
    int bn;
    uint32_t *indirects;
    if (filebno >= NDIRECT + NINDIRECT)//超过限制的块总数
        return -E_INVAL;

    if (filebno < NDIRECT) 
    { //在第一级块数组
        *ppdiskbno = &(f->f_direct[filebno]);
    } 
	 else
  	{
        if (f->f_indirect)  //如何已经存在了二级块 
        {
            indirects = diskaddr(f->f_indirect);
            *ppdiskbno = &(indirects[filebno - NDIRECT]);
        } 
     		else 
        {
            if (!alloc)
                return -E_NOT_FOUND;
            if ((bn = alloc_block()) < 0)
                return bn;
            f->f_indirect = bn;
            flush_block(diskaddr(bn));//将该块缓存写回磁盘，清除dirty位
            indirects = diskaddr(bn);
            *ppdiskbno = &(indirects[filebno - NDIRECT]);
        }
    }

    return 0;
```

2. `file_get_block(struct File *f, uint32_t filebno, char **blk)`：该函数查找文件第filebno个block对应的虚拟地址addr，将其保存到blk地址处。

```c++
// LAB 5: Your code here.
        int r;
        uint32_t *pdiskbno;
        if ((r = file_block_walk(f, filebno, &pdiskbno, true)) < 0) 
        {
            return r;
        }

        int bn;
        if (*pdiskbno == 0) 
        {           //此时*pdiskbno保存着文件f第filebno块block的索引
            if ((bn = alloc_block()) < 0) 
            {
                return bn;
            }
            *pdiskbno = bn;
            flush_block(diskaddr(bn));
        }
        *blk = diskaddr(*pdiskbno);//blk指向实际分配的磁盘块在物理内存中对应的块缓存的虚拟地址
        return 0;
```

#### Exercise 5

文件系统服务端代码在fs/serv.c中，serve()中有一个无限循环，接收IPC请求，将对应的请求分配到对应的处理函数，然后将结果通过IPC发送回去。
对于客户端来说：发送一个32位的值作为请求类型，发送一个Fsipc结构作为请求参数，该数据结构通过IPC的页共享发给FS进程，在FS进程可以通过访问fsreq(0x0ffff000)来访问客户进程发来的Fsipc结构。
对于服务端来说：FS进程返回一个32位的值作为返回码，对于FSREQ_READ和FSREQ_STAT这两种请求类型，还额外通过IPC返回一些数据。

> 实现 `fs/serv.c` 的 `serve_read`
>
> `serve_read` 几乎就是通过调用已经实现好了的 `fs/fs.c` 中的 `file_read` 来实现的（而，`file_read` 也就是一系列对 `file_get_block` 的调用）。`serve_read` 只需要提供用于读文件的 RPC 接口就好了。看看这些注释和 `serve_set_size` 中的代码来了解一下服务端代码的结构是怎样的。

```c++
int
serve_read(envid_t envid, union Fsipc *ipc)
{
    struct Fsreq_read *req = &ipc->read;
    struct Fsret_read *ret = &ipc->readRet;

    if (debug)
        cprintf("serve_read %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

    // Lab 5: Your code here:
    struct OpenFile *o;
    int r;
    r = openfile_lookup(envid, req->req_fileid, &o);
    if (r < 0)      //通过fileid找到Openfile结构
        return r;
    if ((r = file_read(o->o_file, ret->ret_buf, req->req_n, o->o_fd->fd_offset)) < 0)   //调用fs.c中函数进行真正的读操作
        return r;
    o->o_fd->fd_offset += r;
    
    return r;
}
```



### 文件系统接口

我们还需要让其他想要使用文件系统的进程能够和文件系统进程通信。因为其他进程不能直接调用文件系统进程的函数，我们需要通过 RPC (远程过程调用, Remote procedure call) 暴露出访问文件系统进程的抽象方法。这是建立在 JOS 的进程间通信(IPC)机制上的。以读文件为例，调用文件系统服务的过程直观上看起来是这样的：

![](./pic/file_read.png)

#### Exercise 6

> 实现 `fs/serv.c` 中的 `serve_write` 和 `lib/file.c` 中的 `devfile_write`。

`serve_write：`拆解req结构体，将参数传递给file_write(struct File *f, const void *buf, size_t count, off_t offset)，返回总的写字节数。

```c++
int
serve_write(envid_t envid, struct Fsreq_write *req)
{
    if (debug)
        cprintf("serve_write %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

    // LAB 5: Your code here.
    struct OpenFile *o;
    int r;
    if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0) {
        return r;
    }
    int total = 0;
    while (1) 
    {
        r = file_write(o->o_file, req->req_buf, req->req_n, o->o_fd->fd_offset);
        if (r < 0) 
          return r;
        total += r;
        o->o_fd->fd_offset += r;
        if (req->req_n <= total)
            break;
    }
    return total;
}
```

`devfile_write：`客户端进程函数，包装一下参数，直接调用fsipc()将参数发送给FS进程处理。

```c++
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
    // Make an FSREQ_WRITE request to the file system server.  Be
    // careful: fsipcbuf.write.req_buf is only so large, but
    // remember that write is always allowed to write *fewer*
    // bytes than requested.
    // LAB 5: Your code here
    int r;
    fsipcbuf.write.req_fileid = fd->fd_file.id;
    fsipcbuf.write.req_n = n;
    memmove(fsipcbuf.write.req_buf, buf, n);
    return fsipc(FSREQ_WRITE, NULL);
}
```



### Spawning Processes

> 我们已经在 `lib/spawn.c` 中为你提供了创建新进程的 `spawn` 方法，它将一个程序映像从文件系统中读入，并启动一个子进程来运行它。父进程接下来将会独立于子进程继续运行。`spawn` 方法就像是在 UNIX 调用完 `fork` 之后立即在子进程中调用 `exec`。

lib/spawn.c中的spawn()创建一个新的进程，从文件系统加载用户程序，然后启动该进程来运行这个程序。spawn()就像UNIX中的fork()后面马上跟着exec()。
`spawn(const char *prog, const char **argv)`做如下一系列动作：

1. 从文件系统打开prog程序文件
2. 调用系统调用sys_exofork()创建一个新的Env结构
3. 调用系统调用sys_env_set_trapframe()，设置新的Env结构的Trapframe字段（该字段包含寄存器信息）。
4. 根据ELF文件中program herder，将用户程序以Segment读入内存，并映射到指定的线性地址处。
5. 调用系统调用sys_env_set_status()设置新的Env结构状态为ENV_RUNNABLE。

#### Exercise 7

> `spawn` 依赖新的系统调用 `sye_env_set_trapframe` 来初始化新创建的进程的状态。在 `kernel/syscall.c` 中实现 `sys_env_set_trapframe` （不要忘了在 `syscall()` 中分发这个新的系统调用！）
>
> 试试看，调整 `kern/init.c` 让它启动 `user/spawnhello` 这个程序，它将会试图从文件系统启动 `/hello`。

实现sys_env_set_trapframe()系统调用。

```c++
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
    // LAB 5: Your code here.
    // Remember to check whether the user has supplied us with a good
    // address!
    int r;
    struct Env *e;
    if ((r = envid2env(envid, &e, 1)) < 0) 
    {
        return r;
    }
    tf->tf_eflags = FL_IF;
    tf->tf_eflags &= ~FL_IOPL_MASK;         //普通进程不能有IO权限
    tf->tf_cs = GD_UT | 3;
    e->env_tf = *tf;
    return 0;
}
```



#### Exercise 8

> UNIX文件描述符是一个大的概念，包含pipe，控制台I/O。在JOS中每种设备对应一个struct Dev结构，该结构包含函数指针，指向真正实现读写操作的函数。
> lib/fd.c文件实现了UNIX文件描述符接口，但大部分函数都是简单对struct Dev结构指向的函数的包装。
>
> 我们希望共享文件描述符，JOS中定义PTE新的标志位PTE_SHARE，如果有个页表条目的PTE_SHARE标志位为1，那么这个PTE在fork()和spawn()中将被直接拷贝到子进程页表，从而让父进程和子进程共享相同的页映射关系，从而达到父子进程共享文件描述符的目的。

修改lib/fork.c中的duppage()，使之正确处理有PTE_SHARE标志的页表条目。同时实现lib/spawn.c中的copy_shared_pages()。

```c++
static int
duppage(envid_t envid, unsigned pn)
{
    int r;

    // LAB 4: Your code here.
    void *addr = (void*) (pn * PGSIZE);
    if (uvpt[pn] & PTE_SHARE) 
    {
        sys_page_map(0, addr, envid, addr, PTE_SYSCALL);        //对于标识为PTE_SHARE的页，拷贝映射关系，并且两个进程都有读写权限
    }
  else if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) { //对于UTOP以下的可写的或者写时拷贝的页，拷贝映射关系的同时，需要同时标记当前进程和子进程的页表项为PTE_COW
        if ((r = sys_page_map(0, addr, envid, addr, PTE_COW|PTE_U|PTE_P)) < 0)
            panic("sys_page_map：%e", r);
        if ((r = sys_page_map(0, addr, 0, addr, PTE_COW|PTE_U|PTE_P)) < 0)
            panic("sys_page_map：%e", r);
    }
  else {
        sys_page_map(0, addr, envid, addr, PTE_U|PTE_P);    //对于只读的页，只需要拷贝映射关系即可
    }
    return 0;
}
```

`copy_shared_pages():`对于共享页，子进程与父进程拷贝映射关系，实现共享文件描述符。

```c++
static int
copy_shared_pages(envid_t child)
{
    // LAB 5: Your code here.
    uintptr_t addr;
    for (addr = 0; addr < UTOP; addr += PGSIZE) {
        if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) &&
                (uvpt[PGNUM(addr)] & PTE_U) && (uvpt[PGNUM(addr)] & PTE_SHARE)) {
            sys_page_map(0, (void*)addr, child, (void*)addr, (uvpt[PGNUM(addr)] & PTE_SYSCALL));
        }
    }
    return 0;
}
```



#### Exercise 9

> 为了让 shell 能够工作，我们需要找到一种在其中输入的方式。QEMU 会把输出显示到 CGA 显示器并送入输出串口，但是到目前为止，我们只能在内核监视器中输入数据。在 QEMU 中，在图形窗口中输入就是从键盘中输入到 JOS，而在控制台输入就是通过输入串口送入数据。 `kern/console.c` 已经包含了键盘和串口驱动程序，我们从 lab 1 开始内核监视器就在用它，但是现在，你需要把这些接到系统余下的各个部分。

> 在 `kern/trap.c` 中，调用 `kbd_intr` 来处理 `IRQ_OFFSET + IRQ_KBD` 这个陷阱。调用 `serial_intr` 来处理 `IRQ_OFFSET + IRQ_SERIAL` 这个陷阱

在trap_dispacth()中添加上相应类型，调用中断处理函数。

```c++
...
if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD) {
               kbd_intr();
               return;
       }

       if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL) {
               serial_intr();
               return;
       }
...
```



#### Exercise 10

> shell 还不能支持 I/O 重定向。如果能够运行 `sh  这样的代码，而不是直接把脚本中的各种命令打进去就好了。现在，为 `user/sh.c` 添加一个 I/O 重定向运算符 `<`。

目前shell还不支持IO重定向，修改user/sh.c，增加IO该功能。

```c++
runcmd(char* s) {
            ...
            if ((fd = open(t, O_RDONLY)) < 0) {
                cprintf("open %s for write: %e", t, fd);
                exit();
            }
            if (fd != 0) {
                dup(fd, 0);
                close(fd);
            }
            ...
}
```

