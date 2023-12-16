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

## 可变模板参数

当不确定有多少个模板参数的时候可以用到 C++ 的可变参数。

```cpp
// 可变参数模板函数
template<typename... T>
void func(T... args)
{
  
}
```





