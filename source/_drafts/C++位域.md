# C++ 位域

C++ 中的位域（bit-field）只能用于整数类型的成员变量，不能用于其他类型（如浮点数、类对象等）。位域允许你在结构体或类中指定成员变量占用的位数，从而节省内存。

### 位域的基本语法
```cpp
struct MyStruct {
    unsigned int a : 3;  // a 占用 3 位
    unsigned int b : 5;  // b 占用 5 位
    unsigned int c : 10; // c 占用 10 位
};
```

### 位域的限制
1. **类型限制**：位域只能用于整数类型，包括 `int`、`unsigned int`、`signed int`、`char`、`bool` 等。C++11 及以后的标准还支持 `enum` 类型。
   ```cpp
   struct MyStruct {
       int a : 3;        // 合法
       unsigned b : 5;   // 合法
       bool c : 1;       // 合法
       float d : 10;     // 非法，不能用于浮点数
   };
   ```

2. **位数限制**：位域的位数不能超过其基础类型的位数。例如，`int` 通常是 32 位，因此 `int a : 33;` 是非法的。

3. **地址操作**：不能对位域成员取地址，因为位域可能不按字节对齐。
   ```cpp
   MyStruct s;
   int* ptr = &s.a; // 非法，不能取地址
   ```

4. **对齐和填充**：编译器可能会在位域之间插入填充位以满足对齐要求。

### 示例
```cpp
#include <iostream>

struct BitFieldExample {
    unsigned int a : 3;
    unsigned int b : 5;
    unsigned int c : 10;
};

int main() {
    BitFieldExample example;
    example.a = 5; // 3 位，最大值为 7 (2^3 - 1)
    example.b = 20; // 5 位，最大值为 31 (2^5 - 1)
    example.c = 500; // 10 位，最大值为 1023 (2^10 - 1)

    std::cout << "a: " << example.a << std::endl;
    std::cout << "b: " << example.b << std::endl;
    std::cout << "c: " << example.c << std::endl;

    return 0;
}
```

### 总结
- 位域只能用于整数类型的成员变量。
- 位域的位数不能超过其基础类型的位数。
- 不能对位域成员取地址。
- 位域的主要用途是节省内存，特别是在需要处理大量小范围整数时。

如果你需要更灵活的内存管理，可以考虑使用其他技术，如位掩码或自定义的内存布局。