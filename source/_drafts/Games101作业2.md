---
title: Games101 作业2
date: 2023/1/12
math: true
index_img: img/index_img/games101_hw2.png
categories:
- 图形学
- Games101
tags:
- 图形学
- 光栅化
- C++
---

# 作业 2

在作业 2，我们要在作业 1 实现的投影矩阵基础上，对两个三角形进行光栅化，且要求光栅化结果要正确表示两个三角形的前后关系。提高任务为实现 **MSAA** 算法对生成的三角形进行抗锯齿。下面从每个任务点来进行总结。

## 1. 基本的光栅化

我们首先要确定三角形的包围盒（bounding box）。代码如下：

```cpp
// Find out the bounding box of current triangle.
int xMin = floor(std::min(v[0].x(), std::min(v[1].x(), v[2].x())));
int xMax = ceil(std::max(v[0].x(), std::max(v[1].x(), v[2].x())));
int yMin = floor(std::min(v[0].y(), std::min(v[1].y(), v[2].y())));
int yMax = ceil(std::max(v[0].y(), std::max(v[1].y(), v[2].y())));
```

这里定义整型的原因是为了让我们在 for 循环时将 x，y 作为循环的索引，比如（i, j）。个人认为，这其实算是一种编程规范。如果我们直接使用浮点型， clang-tidy 会提醒 `Clang-Tidy: Loop induction expression should not have floating-point type` 。

后面需要采样点时我们只需转型到浮点然后 x, y 分量各加上对应的变量即可，如像素终点（x + 0.5, y + 0.5）。