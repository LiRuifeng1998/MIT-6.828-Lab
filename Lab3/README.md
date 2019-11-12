# JOS实验lab3内存管理

[TOC]

> **组员：李瑞峰 1711347 李汶蔚 1711352 常欢 1711308**

完成情况:

+ 全部练习
+ 挑战

## 实验简介



## 练习部分



### 练习1

PTSIZE=4M

envs物理内存 24个page，也就是98304Byte

映射了PTSIZE



### 练习2

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

### 练习3

### 练习4

### 练习5

### 练习6

### 练习7

### 练习8

### 练习9

### 练习10


