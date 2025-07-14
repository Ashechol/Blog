---
title: C# 枚举器和迭代器
categories:
  - 程序语言
  - CSharp
tags:
  - CSharp
  - 迭代器
date: 2023/9/25
abbrlink: 1086dad3
---
# C# 枚举器和迭代器

在 C# 的使用中，当我们想要遍历一个集合（Collections），如 Array、List、Stack、Dictionary 等的时候，最直接的方法便是使用 `foreach` 来遍历整个集合。

> C# 集合的概念对应 C++ 中的 STL 容器

```csharp
List<int> list = new List(new []{1, 2, 3, 4});
int[] array = {1, 2, 3, 4};


foreach(int num in list)
{
    // ......
}

foreach(int num in array)
{
    // ......
}
```

foreach 之所以能够遍历这些集合，得益于他们都提供了一个枚举器（Enumerator) 的方法 `GetEnumerator()` 。正是通过枚举器，才能在 `foreach` 循环中遍历所有元素。

## 1. 枚举器（Enumerator）

### 1.1 枚举器接口（IEnumerator)

要自己实现一个枚举器，需要继承 `IEnumerator` 或 `IEnumerator<T>` 接口。

```csharp
public interface IEnumerator
{
    bool MoveNext();
	object Current { get; }
    void Reset();
}

public interface IEnumerator<out T> : IDisposable, IEnumerator
{
    new T Current { get; }
}
```

* `MoveNext()` ：每次调用该方法枚举器指向下一个元素。不能继续遍历则返回 `false` ；
* `Current` ：该属性返回当前枚举器指向的元素。根据是否是泛型版本，返回值的类型有所不同；
* `Reset()` ：将枚举器重置到初始状态；

下面是一个实现了二叉树层序遍历枚举器的例子：

```cpp
private class Enumerator : IEnumerator<TreeNode<T>>
{
    private readonly TreeNode<T> _root;
    private readonly Queue<TreeNode<T>> _que = new ();

    public Enumerator(TreeNode<T> root)
    {
        _root = root;
        _que.Enqueue(_root);
    }

    public bool MoveNext()
    {
        if (_que.Count == 0)
            return false;

        Current = _que.Peek();
        _que.Dequeue();

        if (Current?.left != null)
            _que.Enqueue(Current.left);
        if (Current?.right != null)
            _que.Enqueue(Current.right);

        return true;
    }

    public void Reset()
    {
        Current = null;
        _que.Clear();
        _que.Enqueue(_root);
    }

    public TreeNode<T> Current { get; private set; }

    object IEnumerator.Current => Current;

    public void Dispose() {}
}
```

要通过枚举器来直接遍历也十分简单，代码结构如下：

```csharp
IEnumerator<TreeNode<int>> ie = node.GetIEnumerator();

while (ie.MoveNext())
   Console.WriteLine(ie.Current.val)
```

### 1.2 可枚举接口（IEnumerable）

要让 foreach 能正确得到我们写好的枚举器，则二叉树类必须实现 `IEnumerable` 或 `IEnumerable<T>` 接口。

```csharp
public interface IEnumerable
{

    IEnumerator GetEnumerator();
}

public interface IEnumerable<out T> : IEnumerable
{
    new IEnumerator<T> GetEnumerator();
}
```

所以我们的二叉树类的代码框架，最后应该如下所示（完整源码放到最后）：

```csharp
public class TreeNode<T> : IEnumerable<TreeNode<T>>
{
    private class Enumerator : IEnumerator<TreeNode<T>>
    {
        // 已在 1.1 实现
    }
    
    public T val;
    public TreeNode<T> left;
    public TreeNode<T> right;

    public TreeNode(T val, TreeNode<T> left = null, TreeNode<T> right = null)
    {
        this.val = val;
        this.left = left;
        this.right = right;
    }
	
    public IEnumerator<TreeNode<T>> GetEnumerator() => new Enumerator(this);
    
    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
```

## 2. 迭代器（Iterator）

以上枚举器的实现方法还是比较复杂的。不过从 C# 2.0 版本起，我们有了更简单的方式来实现枚举器和可枚举类型。我们只需通过简短的代码，来实现枚举的核心过程，剩下枚举器的创建由编译器来负责。这种实现方法被叫做迭代器。

迭代器有两个核心组成部分：

*  返回值为泛型枚举器类型 `IEnumerator<T>` ，这枚举器的具体实现由编译器负责；
* `yield return` 语句，该语句声明了这是枚举中的下一项；

下面是一个最简单的迭代器代码：

```csharp
public IEnumerator<string> BlackAndWhite()
{
    yield return "black";
    yield return "gray";
    yield return "white";
}
```

通过返回的枚举器的 `MoveNext()` 方法和 `Current` 属性，我们可以依次遍历出迭代器中的三个颜色字符串。

> 如果写过 Unity 的协程，到这里应该能够理解协程的大致原理了。

下面可以用迭代器的方式去改写 1.1 中实现的枚举器了，如下所示：

```csharp
public IEnumerator<TreeNode<T>> LevelOrderIterator()
{
    // 这段代码也可以直接放在 GetEnumerator 中，它本身也符合迭代器的结构
    Queue<TreeNode<T>> que = new Queue<TreeNode<T>>();
    que.Enqueue(this);

    while (que.Count > 0)
    {
        var current = que.Peek();
        que.Dequeue();

        yield return current;

        if (current.left != null) que.Enqueue(current.left);
        if (current.right != null) que.Enqueue(current.right);
    }
}

public IEnumerator<TreeNode<T>> GetEnumerator() => LevelOrderIterator();
```

### 2.1 产生可枚举类型的迭代器

当迭代器的返回值是 `IEnumerable<T>` 的时候，就是一个产生可枚举类型的迭代器。他可以直接交给 `foreach` 来遍历。

这样做有个好处便是，我们可以实现多个不同枚举过程的迭代器供 foreach 选择。

```csharp
class TreeNode<T>
{
    public IEnumerable<TreeNode<T>> LevelOrder()
    {
        // ......
    }
    
    public IEnumerable<TreeNode<T>> Preorder()
    {
        // ......
    }
    
    public IEnumerable<TreeNode<T>> Inorder()
    {
        // ......
    }
    
    // 也可以写成只读属性
    public IEnumerable<TreeNode<T>> Postorder
    {
        get
        {
            // ......
        }
    }
}

foreach(var current in root.Preorder())
{
    
}
```

## 3. 源码

### 3.1 枚举器版

```csharp
public class TreeNode<T> : IEnumerable<TreeNode<T>>
{
    private class Enumerator : IEnumerator<TreeNode<T>>
    {
        private readonly TreeNode<T> _root;
        private readonly Queue<TreeNode<T>> _que = new ();

        public Enumerator(TreeNode<T> root)
        {
            _root = root;
            _que.Enqueue(_root);
        }
        
        public bool MoveNext()
        {
            if (_que.Count == 0)
                return false;
            
            Current = _que.Peek();
            _que.Dequeue();
                
            if (Current?.left != null)
                _que.Enqueue(Current.left);
            if (Current?.right != null)
                _que.Enqueue(Current.right);

            return true;
        }

        public void Reset()
        {
            Current = null;
            _que.Clear();
            _que.Enqueue(_root);
        }

        public TreeNode<T> Current { get; private set; }

        object IEnumerator.Current => Current;

        public void Dispose() {}
    }
    
    public T val;
    public TreeNode<T> left;
    public TreeNode<T> right;

    public TreeNode(T val, TreeNode<T> left = null, TreeNode<T> right = null)
    {
        this.val = val;
        this.left = left;
        this.right = right;
    }

    public TreeNode(T[] values)
    {
        CreateTree(values);
    }
	
    // 从当前结点创建子树
    public void CreateTree(T[] values)
    {
        if (default(T) != null)
            throw new InvalidOperationException("Tree<T> requires T to be a nullable type");

        if (values.Length == 0) return;

        var i = 0;
        if (val == null)
        {
            val = values[0];
            ++i;
        }
        
        var que = new Queue<TreeNode<T>>();
        que.Enqueue(this);

        for (; i < values.Length; i += 2)
        {
            var current = que.Peek();
            que.Dequeue();

            if (values[i] != null)
            {
                current.left = new TreeNode<T>(values[i]);
                que.Enqueue(current.left);
            }

            if (i + 1 < values.Length && values[i + 1] != null)
            {
                current.right = new TreeNode<T>(values[i + 1]);
                que.Enqueue(current.right);
            }
        }
    }

    public IEnumerator<TreeNode<T>> GetEnumerator() => new Enumerator(this);
    
    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
```

### 3.2 迭代器版本

```csharp
public class TreeNode<T> : IEnumerable<TreeNode<T>>
{
    public T val;
    public TreeNode<T> left;
    public TreeNode<T> right;

    public TreeNode(T val, TreeNode<T> left = null, TreeNode<T> right = null)
    {
        this.val = val;
        this.left = left;
        this.right = right;
    }

    public TreeNode(T[] values)
    {
        CreateTree(values);
    }

    public void CreateTree(T[] values)
    {
        // 同枚举器版本
    }

    public IEnumerator<TreeNode<T>> GetEnumerator()
    {
        var que = new Queue<TreeNode<T>>();
        que.Enqueue(this);

        while (que.Count > 0)
        {
            var current = que.Peek();
            que.Dequeue();

            yield return current;

            if (current.left != null) que.Enqueue(current.left);
            if (current.right != null) que.Enqueue(current.right);
        }
    }
    
    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
```

