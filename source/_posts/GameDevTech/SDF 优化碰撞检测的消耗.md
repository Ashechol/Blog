---
title: 基于 SDF 的摇杆移动（总结）
math: true
categories:
  - 游戏开发技术
  - 腾讯游戏开发精粹
tag:
  - 有符号距离场
  - SDF
  - 碰撞检测
abbrlink: 2a3299f7
date: 2023-10-21 9:00:00
---



# 基于 SDF 的摇杆移动（总结）

## 1. 什么是有号距离场（SDF）

有号距离场（Signed Distance Field，SDF）表示空间中的点到形状表面（如障碍物）的最短距离。所以 SDF 实际是一个纯量场。

> 纯量场（Scalar Field）是物理学中的一个概念。
>
> 它描述了在空间中的每个点上都具有一个标量值（纯量值）的物理量。纯量是一个只有大小，没有方向的物理量。

通常，定义距离的负值为内部到表面的最短距离，正值为外部到表面的最短距离。数学公式如下：

定义函数 $\phi:\mathbb{R}^n\rightarrow\mathbb{R}$ 对于形状点集 $\boldsymbol S$ 有
$$
\phi(\boldsymbol x)=
\begin{cases}
\min||\boldsymbol x-\boldsymbol y||,\boldsymbol x\notin\boldsymbol S\\
-\min||\boldsymbol x-\boldsymbol y||,\boldsymbol x\in\boldsymbol S
\end{cases}
$$

### 1.1 SDF 有什么用

在游戏开发中，最常见的一个功能就是要计算角色是否和障碍物碰撞。在角色较多的时候，使用物理引擎实时计算碰撞会造成比较大的时间上的开销。

为此，我们可以利用 SDF 的特点，提前离线计算出整张图的距离场。如果想要知道当前点是否与障碍物碰撞，直接查表并和角色的半径比较即可（时间复杂度 $O(1)$）。这是一个典型的空间换时间的方法。

## 2. 基于栅格的 SDF 计算方法

一张地图可以有无数多的点，我们不可能将每个点的 SDF 数据都记录下来。因此根据障碍精度对地图进行栅格化，仅计算出栅格中的每个点的 SDF 数据。对于任意一个点的 SDF，通过找到它 **最近的四个点** 的 SDF 值，然后进行 [**双线性插值**](https://blog.ashechol.top/posts/d247a4eb.html#双线性插值bilinear-interpolation) 求出。

在计算 SDF 前，需要赋予栅格初始值。阻挡区域为 0，可通过区域为 1。

<img src="https://img.ashechol.top/picgo/raster_map.png" alt="灰色表示0，白色表示1" style="zoom:60%;" />

### 2.1 栅格 SDF 计算

计算 SDF 可以利用欧式距离转换（Euclidean Distance Transform，EDT）求出每个栅格点到最近阻挡区的距离平方，然后开根。

$$
d(x,y)=\sqrt{\bf{EDT}(x,y)}
$$

> EDT 的计算方式有很多种，比如基于光栅扫描的 8ssedt 算法（适合 CPU 计算）和独立扫描 Saito Toiwaki 算法（利用 GPU 多线程计算效果好于 8ssedt）

最后计算出的 SDF 如下：

<img src="https://img.ashechol.top/picgo/sdf.png" style="zoom:60%;" />

当我们要获取 SDF 上任意点的值，只需找到它最近的四个离散点，然后进行双线性插值。



