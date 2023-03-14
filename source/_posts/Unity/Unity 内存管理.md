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

原生内存里面存储了项目中的场景、资源（assets，比如纹理、网格）、图形API、图形驱动、子系统、插件缓存以及其他的内存分配。用户通过封装的上层 C# 接口来间接访问和操作这些内存中的数据。

## 2. 内存的管理

### 2.1 托管内存

对于托管堆，是由垃圾回收器自动管理其内存的申请和释放。不过在一些特殊情况下，需要手动调用垃圾回收时可以使用代码 `System.GC.Collect()` 。

不过需要注意的是，手动调用 GC 会完整扫描整个堆，可能会导致游戏卡顿。

此外，GC 的触发并不会回收原生内存中对应的游戏对象（资产，或者说资源）。所以需要通过 Unity 提供的 API 管理原生内存中的资源的加载和释放。

### 2.2 原生内存（资源原理）

#### 2.2.1 资源的加载方式

Unity 的资源加载方式主要分为两种：

* **静态加载**：在 Editor 的 Inspector 中为 GameObject 直接设置资源；
* **动态加载**：在游戏运行的时候加载资源到内存然后通过代码设置资源。

> 在 [Unity 官方文档](https://docs.unity.cn/2019.4/Documentation/Manual/LoadingResourcesatRuntime.html) 中只提到了资源的动态加载，不过在资源文件夹小结提到了：
>
> 资源文件夹里面的资源不必在 Inspector 窗口中提前给任何 GameObject 设置，而是通过 `Resources.Load()` 在游戏运行时加载。
>
> 为了方便与动态对应，我们将在 Inspector 窗口中直接给 GameObject 设置资源的方式称为资源的静态加载。

静态加载的方式最简单直观但是会有以下几个问题：

* 有的资源是需要在游戏运行时根据情况加载的；
* 随着游戏体量的增大，资源数量的增多通过 Inspector 来手动设置所有资源将会越来越麻烦；
* 不能将资源打包为更新包，单个游戏客户端的体积会变得非常大。

动态加载便是为了解决以上问题，尽管在操作上需要通过程序代码，而且处理不当可能会出现些其他问题，但是这是值得的。

#### 2.2.2 资源的动态加载和卸载

目前 Unity 有三种动态资源加载卸载的方法。

##### Resources

名字为 Resources 的文件夹，在 Unity 引擎中被视作采用动态加载的资源的根目录。

通过 [`Resources`](https://docs.unity3d.com/ScriptReference/Resources.html) 系列 API 对 Resources 文件夹中的资源进行动态加载和卸载。常用的方法有：

* [`Resource.Load()`](https://docs.unity3d.com/ScriptReference/Resources.Load.html) ：加载指定资源并返回它；
* [`Resources.UnloadAsset()`](https://docs.unity3d.com/ScriptReference/Resources.UnloadAsset.html)：卸载指定资源；
* [`Resources.UnloadUnusedAssets()`](https://docs.unity3d.com/ScriptReference/Resources.UnloadUnusedAssets.html)：卸载未使用的资源；
  * 注意，[该方法内部会调用 GC](https://forum.unity.com/threads/resources-unloadunusedassets-vs-gc-collect.358597/)，所以没有必要在其之后调用 `GC.Collect()` 释放托管堆内的内存；

> Resources 的方法全为静态方法

更多的方法详情可以参考 [Unity 官方文档](https://docs.unity3d.com/ScriptReference/Resources.html) 。

##### AssetBundle

Resources 解决了资源在运行时动态加载和卸载的问题，但是没有解决资源的打包更新问题（比如 DLC 更新包）。为此需要使用 AssetBundle 。

AssetBundle 的使用比起 Resources 要复杂一些。更详细的说明参考文章 [AssetBundle 总结](https://blog.ashechol.top/posts/5e5b801b.html) 。

下面列出 [`AssetBundle`](https://docs.unity.cn/2019.4/Documentation/ScriptReference/AssetBundle.html) 常见方法：

* [`AssetBundle.LoadFromFile()`](https://docs.unity.cn/2019.4/Documentation/ScriptReference/AssetBundle.LoadFromFile.html)：从硬盘上加载 AB 包，然后返回它。该方法是静态方法；
* [`AssetBundle.LoadAsset()`](https://docs.unity.cn/2019.4/Documentation/ScriptReference/AssetBundle.LoadAsset.html)：从 AB 中加载资源，然后返回它的实例；
* [`AssetBundle.Unload()`](https://docs.unity.cn/2019.4/Documentation/ScriptReference/AssetBundle.Unload.html)：卸载该实例的 AB 包，可传入 bool 值选择是否同时卸载 AB 包中已经被加载的资源；

要卸载 AB 包中的已加载的单个资源，仍使用 `Resources.UnloadAsset()` 。

##### Addressables

Addressables 是新版本Unity (2020.2 及以后) ，为了降低 AssetBundle 的使用难度推出的新工具包（Package）。

详细说明可以参考 [Addressables 总结](https://blog.ashechol.top/posts/e6335314.html)

## 参考

[Unity - Manual: Memory in Unity](https://docs.unity3d.com/Manual/performance-memory-overview.html)

[Resources.UnloadUnusedAssets vs. GC.Collect - Unity Forum](https://forum.unity.com/threads/resources-unloadunusedassets-vs-gc-collect.358597/)

[Unity - Manual: Loading Resources at Runtime ](https://docs.unity3d.com/Manual/LoadingResourcesatRuntime.html)

[Unity资源的加载释放最佳策略探讨](https://www.jianshu.com/p/f21c455e5f17)

[Unity - Manual: Addressables](https://docs.unity3d.com/Manual/com.unity.addressables.html)
