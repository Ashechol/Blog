---
title: Unity 内存管理
date: 2023/3/13
categories:
  - Unity
tags:
  - 内存
abbrlink: 80654f68
---

# Unity 内存管理

## 1. Unity 内存分类

在 Unity 程序运行的时候，有三个内存管理层，分别是：

* 托管内存（managed memory）
* C# 非托管内存（unmanaged memory）
* 原生（本机）内存（native Memory）

### 1.1 托管内存

脚本虚拟机（scripting virtual machine，VM）实现了托管内存系统（有时候也被叫做脚本内存系统）。VM 将托管内存分成了三个部分：

* 托管堆（managed heap）
  * 同 CLR 的托管堆一样，被垃圾回收器（GC）管理。
* 脚本栈（scripting stack）
* 原生 VM 内存（native VM memory）
  * 里面包含一些与生成的可执行代码相关的内存，比如泛型的使用，反射使用的类型的元数据。以及一些维持 VM 运行所需的内存。

> 在 Unity 中， C# 的运行时实际上就是脚本虚拟机或者叫做脚本后端（scripting backend） 

Unity 脚本后端有两种：

* Mono：基于 .NET 标准的公共语言运行时（CLR）；
* IL2CPP：Unity 自己研发一套脚本后端，不完全遵守 .NET 标准。

> 两者的区别可以参考 [C# 运行时与垃圾回收](https://blog.ashechol.top/posts/70fb648.html) 中 [公共语言运行时](https://blog.ashechol.top/posts/70fb648.html#%E5%85%AC%E5%85%B1%E8%AF%AD%E8%A8%80%E8%BF%90%E8%A1%8C%E6%97%B6clr) 和 [Unity C# 运行时](https://blog.ashechol.top/posts/70fb648.html#unity-c-%E8%BF%90%E8%A1%8C%E6%97%B6) 两个小结的内容。

#### 垃圾回收器

Mono 和 IL2CPP 的垃圾回收器都是使用的 [Boehm-Demers-Weiser GC](https://github.com/ivmai/bdwgc) （简称 Boehm GC）。

Boehm GC 支持最基本的 **标记-清除** 算法，也可以开启 **增量式+分代** 功能（`GC_enable_incremental()`）。

在 Unity 编辑器中，`Project Settings`->`Player`->勾选 `Use incremental GC` 可以开启该功能（默认开启）。

### 1.2 非托管内存

C# 非托管内存层（C# unmanaged memory layer）允许你用 C# 的方式访问原生内存来微调（fine-tune）内存分配。

通过使用 `Unity.Collections` 域名空间下的数据结构，如 `NativeArray`，即可访问非托管内存。

如果使用 ESC 下的作业系统（Job system）和 Burst，则必须使用 C# 非托管内存。

### 1.3 原生内存

Unity 引擎的底层是通过 C/C++ 实现的。它有一套自己的内存管理系统，也被称作 **原生内存** 。绝大多数情况系，用户是不能直接访问或者修改这部分内存的。

原生内存里面存储了项目中的场景、资产（assets，比如纹理）、图形API、图形驱动、子系统、插件缓存以及其他的内存分配。用户通过封装的上层 C# 接口来间接访问和操作这些内存中的数据。

## 2. 内存释放

### 2.1 托管内存的释放

对于托管堆，是由垃圾回收器自动管理其内存的申请和释放。不过在一些特殊情况下，需要手动调用垃圾回收时可以使用代码 `System.GC.Collect()` 。

不过需要注意的是，手动调用 GC 会完整扫描整个堆，可能会导致游戏卡顿。此外，GC 的触发并不会回收原生内存中对应的游戏对象（资产，或者说资源）。

### 2.2 原生内存的释放（资源释放）

#### 2.2.1 资产的加载方式



#### 2.2.2 资产的动态加载



#### 2.2.3 资产的动态卸载



## 参考

[Unity - Manual: Memory in Unity](https://docs.unity3d.com/Manual/performance-memory-overview.html)

[Resources.UnloadUnusedAssets vs. GC.Collect - Unity Forum](https://forum.unity.com/threads/resources-unloadunusedassets-vs-gc-collect.358597/)

[Unity - Manual: Loading Resources at Runtime ](https://docs.unity3d.com/Manual/LoadingResourcesatRuntime.html)
