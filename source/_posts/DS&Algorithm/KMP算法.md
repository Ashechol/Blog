---
title: KMP算法
math: true
tags:
  - KMP
categories:
  - 数据结构和算法
---



# KMP算法

### 匹配算法

KMP算法的目标是，避免重复匹配从而减小时间复杂度。如：

*   字符串：`aabaabaafbaa`

*   模式串：`aabaaf`

按照暴力模拟的思路。遍历到第六个字符`b`时，与模式串的第六个字符`f`不匹配，则需要从第二个字符`a`重新开始匹配。

而**KMP**算法可以找出之前已经匹配过的子串`aa` 从而字符串可以继续往后遍历不用回退，只用回退模式串的到第三个字符`b`。

<img src="https://img.ashechol.top/algorithm/KMP_1.jpg" style="zoom:50%;" />

### 前缀表

**KMP**匹配的方法是基于一个叫做**前缀表**的数组（有时候也被称为`prev数组`或`next数组`）。通过前缀表，可以快速得到模式串当前字符退回的位置。

例如`aabaaf`的前缀表为：`[0, 1, 0, 1, 2, 0]`。为了方便代码的实现，一般会往左移（即全部减一）

`[-1, 0, -1, 0, 1, -1]`。
$$
\begin{aligned}
-1\;0\;1\;2\;3\;4\;5 \\
a\;a\;b\;a\;a\;f 
\end{aligned} 
$$

使用两个指针`pre`和`suf`：

*   `pre = -1`

*   `suf = 0`

`str[pre]`是前缀的最后一个字符，`str[suf]`是后缀的最后一个字符

如果`str[pre]==str[suf]`则两者继续向后比较，`next[suf]`记录当前`pre`的位置。

如果两者不相等。则pre需要按照next

