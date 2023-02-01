---
title: CSharp 引用类型踩坑
date: 2022/6/24
index_img: /img/illustration/dragon.jpg
banner_img: /img/illustration/dragon.jpg
categories:
  - 程序语言
  - CSharp
tags:
  - CSharp
  - 引用类型
abbrlink: 5a52e689
---

## 一、C# 的数据类型

C# 的数据类型分为 **值类型** 和 **引用类型** 。

<img src="https://docs.microsoft.com/zh-cn/dotnet/csharp/programming-guide/types/media/index/value-reference-types-common-type-system.png" title="" alt="" data-align="center">

### 1.1. 值类型

如：

* 结构体（struct）

* 枚举（enum）

* 数值类型

值类型派生自 [System.ValueType](https://docs.microsoft.com/zh-CN/dotnet/api/system.valuetype)（派生自 [System.Object](https://docs.microsoft.com/zh-CN/dotnet/api/system.object) ）。 值类型变量直接包含其值，没有单独的堆分配或垃圾回收开销。

### 1.2. 引用类型

如：

* 类（class）

* 接口（interface）

* 委托（delegate）

* 字符串（string）

* 数组（Array）

引用类型类似于 C 和 C++ 中的指针的概念。在声明引用类型变量时，它将包含值 `null`，直到你将其分配给该类型的实例，或者使用 `new` 运算符创建一个。

## 二、引用类型的赋值陷阱

### 2.1. 陷阱

```csharp
using System;

namespace Experiment
{
    class TestClass
    {
        public int a;
        public int b;
        public void GetNewValue(TestClass t)
        {
            TestClass b = new TestClass() { a = 3, b = 4 };
            t = b;
        }
    }

    internal class Program
    {
        static void Main(string[] args)
        {
            TestClass a = new TestClass() { a = 1, b = 2 };
            a.GetNewValue(a);
        }
    }
}
```

如以上 C# 代码，TestClass 的对象 a 调用 `GetNewValue` 方法。然而，运行后，对象实例 a 的成员变量的值并未改变为 3，4。

为了方便查看地址的信息，以下用等价的 C++ 代码来实验：

```cpp
#include <iostream>
using namespace std;

class TestClass
{
public:
    int a;
    int b;
};

void GetNewValue(TestClass* t)
{
    cout << "t赋值前：" << t << endl;
    TestClass* b = new TestClass;
    b->a = 3;
    b->b = 4;
    t = b;
    cout << "t赋值后：" << t << endl;
}


void main()
{
    TestClass* a = new TestClass;
    a->a = 1;
    a->b = 2;
    cout << "a赋值前：" << a << endl;
    GetNewValue(a);
    cout << "a赋值后：" << a << endl;
}
```

运行后的结果是：

```con
a赋值前：00AB8FC8
t赋值前：00AB8FC8
t赋值后：00AB8D60
a赋值后：00AB8FC8
```

可以看出，形参 t 在 a 传入后，其指向的地址为 a 对象实例所在的地址，然后 `t = b` 之后，t 指向了 b 对象实例的所在地址，而这个而改变并没有发生在 a 上。

在 C# 中，引用类型变量的赋值实质上也是发生了以上 C++ 代码的过程。

### 2.2. 解决方法

解决方法有两种思路。

第一种是不给 t 赋值，二是通过 t 直接修改 a 成员变量的值：

```csharp
t.a = 3;
t.b = 4;
```

第二种是使用 `ref` 或 `out` 关键字，这种方法就类似于 C++ 的引用形参

```csharp
void GetNewValue(ref TestClass t)
{
    TestClass b = new TestClass() { a = 3, b = 4 };
    t = b;
}
// 或
void GetNewValue(out TestClass t)
{
    TestClass b = new TestClass() { a = 3, b = 4 };
    t = b;
}
```

> 关于 ref，out 以及 in 的区别
> 
> * out：设置用作此形参的实参的值，方法内必须给参数赋值。
> 
> * ref：可修改用作此形参的实参的值。（类似 C++ 的引用形参）
> 
> * in：不会修改用作此形参的实参的值。（类似 C++ 常引用形参）
> 
> 详见 [编写安全有效的 C# 代码 | Microsoft Docs](https://docs.microsoft.com/zh-cn/dotnet/csharp/write-safe-efficient-code)
