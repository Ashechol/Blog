---
title: C++ 模板编程
categories:
  - 程序语言
  - CPP
tags:
  - CPP
---

# C++ 模板编程

## 基础

### 模板函数

```cpp
// 单模板参数
template<typename T>
void Func(T value);

template<typename T>
T Func(T a, T b);

// 多模板参数
template<typename T1, typename T2>
T2 Func(T1 a, T1 b);
```

### 模板类/结构体

```cpp
// 单模板参数
template<typename T>
class Test1
{
public:
    T val;
    void Func(T val);
};

// 多模板参数
template<typename T1, typename T2>
class Test2
{
public:
    T1 val;
    void Func(T2 val);
    T2 Func(T1 v1, T2 v2);
};
```

## 特化
```cpp
// 基础模板
template<typename T1, typename T2, typename T3>
void Func(T1 a, T2, b, T3 c);

// 偏特化
template<typename T2>
void Func(int a, T2 b, float c);

// 全特化
template<>
void Func(int a, bool b, float c);
```

## 可变模板参数

### 老方法

在写函数的时候，有时会遇到需要传入不确定数量参数的情况。在 C 的时候可以使用 `stdarg.h` 下的系列宏来实现。

```cpp
#include <cstdarg>

int Sum(int cnt, ...)
{
    va_list args;
    va_start(args, cnt);
    int sum = 0;
    for (int i = 0; i < cnt; ++i)
    {
        sum += va_arg(args, int);
    }

    va_end(args);

    return sum;
}
```

此处 `cnt` 表示传入参数的数量。

> 相关资料可以参考 https://en.cppreference.com/w/cpp/utility/variadic

### 新方法：参数包

在 `C11` 之后，引入了 **参数包（Parameter pack）**这一个特性。可以配合 C++ 的模板（template）来实现各种可变参数的功能。

```cpp
template<typename... Args>
int Sum(Args... args);
```

这里的 `Args... args` 就是一个参数包，要访问参数包中的参数，有两种方法。

**递归的方法**

```cpp
// 只有一个参数时调用，相当于递归的终止条件
template<typename T>
void print(T val)
{
    std::cout << val << std::endl;
}
// 递归的方式来剥离没有个参数
template<typename T, typename... Args>
void print(T start, Args... args)
{
    std::cout << start << std::endl;
    print(args...);
}
```

**包展开方法（Pack Expansion）**

> 包展开的详细信息可以参考 https://en.cppreference.com/w/cpp/language/parameter_pack

```cpp
template<typename... Args>
void print(Args... args)
{
    ((std::cout << args << " "), ...);
    std::cout << std::endl;
}
```

这里的 `(std::cout << args << " ")` 即是包展开的一个单元。

可以在 [C++ Insights](https://cppinsights.io/) 中看到这段代码会实际展开成如下所示（假设传入三个参数）：

```cpp
template<typename ... Args>
void print(Args... args)
{
  (((std::cout << args) << " ") , ...);
  std::cout.operator<<(std::endl);
}

/* First instantiated from: insights.cpp:12 */
#ifdef INSIGHTS_USE_TEMPLATE
template<>
void print<int, int, int>(int __args0, int __args1, int __args2)
{
  (std::operator<<(std::cout.operator<<(__args0), " ")), 
  (std::operator<<(std::cout.operator<<(__args1), " ")),
  (std::operator<<(std::cout.operator<<(__args2), " "));
  std::cout.operator<<(std::endl);
}
#endif
```

如果仅一行代码还是没法对参数完成操作，可以考虑使用函数来作为包展开的单元：

```cpp
#include <iostream>

template<typename... Args>
void print(int& sum, Args... args)
{
    (Add(sum, args), ...);
}

template<typename T>
void Add(int& sum,  T val)
{
    sum += val;
    std::cout << val << std::endl;
}

int main()
{
    int sum = 0;
    print(sum, 3, 2, 3, 4);
    std::cout << sum << std::endl;
    return 0;
}
```

当然匿名函数也是可以的。

```cpp
template<typename... Args>
void print(int& sum, Args... args)
{
    ([&]()->void{
        sum += args;
        std::cout << args << std::endl;
    }(), ...);
}
```

## 为模板实例化添加限制

在实际开发中，有时会遇到不希望模板被某种类型实例化的情况。从 C11 开始，引入了 `std::enable_if` 来处理这个问题。它会在满足条件的时候使用一个指定的类型来定义变量或者函数（本文后面的例子都是函数），否则会产生报错（当然可以捕获这个异常并输出报错日志，来保证程序可以继续运行）。

其中的布尔值条件可以通过 `std::is_xxxx` 来进行设置。一下为几种常见的：

* `std::is_same`：判断两个类型是否一样；
* `std::is_class`：是否是某个类；
* `std::is_base_of`：是否是某个类的子类，这里可以交换顺序判断是否是某个类的父类；
* `std::is_array`：是否是数组；

### 用法

```cpp
template<typename T>
typename std::enable_if<true, int>::type
AddTwo(T val)
{
    return val + 2;
}
```

这里有几个需要注意的关键点：

* `enable_if<true, int>::type`：这里第一个参数是 `true` 的时候，后面的 `type` 才有效，`type` 对应的类型是第二个参数的类型，即 `int`；
  * 此处如果函数返回值是 void，则可以省略第二个参数；
* 要用 `typename` 修饰 `enable_if<true, int>::type`，这样才能表示一个完整的类型，不然会报错。

接下来用 `is_same` 来替换第一个参数，从而让改模板不能生成 `std::string` 所对应的实例。

```cpp
template<typename T>
typename std::enable_if<!std::is_same<std::string, T>::value, int>::type
AddTwo(T val)
{
    return val + 2;
}
```

## 来点复杂的应用

#### 只接收 int 和 float 类型

上文实现的 `print()` 函数，我们想要限制传入的参数必须是 `int` 或者 `float` 类型，同时让它返回 `sum`，可以写成代码如下：

```cpp
template<typename T>
struct is_float : std::is_same<T, float> {};

template<typename T>
struct is_int : std::is_same<T, int> {};

template<typename... Args>
typename std::enable_if<((is_float<Args>::value || is_int<Args>::value ) && ...), float>::type
print(Args... args)
{
    int sum = 0;
    ([&]()->void{
        sum += args;
        std::cout << args << std::endl;
    }(), ...);

    return sum;
}

/**
std::cout << print(1, 2, 3, 4) << std::endl;       // 没问题，最后输出 10
std::cout << print(1, "123", 3.f, 4) << std::endl; // IDE 报错，有参数不是 int 类型
**/
```

#### 禁止使用模板类作为模板参数的模板函数

```cpp
template <typename T>
struct is_template_class : std::false_type {};

template<template<typename...> class Tmp, typename... T>
struct is_template_class<Tmp<T...>> : std::true_type {};

template<typename T>
typename std::enable_if<!is_template_class<T>::value>::type
Func(T value)
{
    std::cout << "Not a template class" << std::endl;
}
```

#### 禁止使用 vector 容器作为模板参数的模板函数

```cpp
template <typename T>
struct is_vector : std::false_type {};

template<template<typename...> class Tmp, typename... T>
struct is_vector<Tmp<T...>> : std::is_same<Tmp<T...>, std::vector<T...>> {};

template<typename T>
typename std::enable_if<!is_vector<T>::value>::type
Func(T value)
{
    std::cout << "Not Vector" << std::endl;
}
```



 
