---
title: Games101 作业1：变换
date: 2023/1/5
math: true
index_img: img/index_img/games101_hw1.png
categories:
- 图形学
- Games101
tags:
- 图形学
- C++
---

# 作业 1

作业1是对变换章节所学知识的应用和练习。作业提供了一个基于 **Eigen** 和 **OpenCV** 库的光栅化程序框架。该框架定义了一个等腰三角形，需要我们在 main.cpp 中实现以下三个任务：

1. 实现 `get_model_matrix` 函数中的旋转变换矩阵，让等腰三角形绕 Z 轴旋转；
2. 实现 `get_projection_matrix` 函数中的投影变换矩阵，使等腰三角形正确投影到显示器上；
3. 实现一个 `get_rotation` 函数， 使等腰三角形可以绕任意轴旋转；

## 1. 绕 Z 轴旋转

这个功能点直接使用绕 Z 轴的旋转矩阵即可。

需要注意的是，C++ 中三角函数输入值是弧度值，而 `get_model_matrix` 的形参输入是角度值，所以我们需要转换。
$$
1^\circ=\frac{\pi}{180}\mathbf{rad}
$$
代码实现如下：

```cpp
Eigen::Matrix4f get_model_matrix(float rotation_angle)
{
    Eigen::Matrix4f model = Eigen::Matrix4f::Identity();

    // input of cos and sin function is radian,
    // so we need convert rotation_angle from degree to radian
    rotation_angle *= MY_PI / 180;
    float c = cos(rotation_angle);
    float s = sin(rotation_angle);

    Rotate around Z-axis
    model << c, -s, 0, 0,
             s, c, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1;

    return model;
}
```

## 2. 投影变换矩阵

`get_projection_matrix` 函数的形参是由 eye_fov（垂直视角）、aspect_ratio（纵横比）、dNear（近平面距离）、dFear（远平面距离）构成。所以需要利用视角、纵横比和 zNear 的关系才能得到近平面的 l、r、t、b 参数。具体公式推导见 [笔记](https://blog.ashechol.top/2023/01/04/computer%20graphic/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E7%AC%94%E8%AE%B0(1)%EF%BC%9A%E5%8F%98%E6%8D%A2/#%E8%A7%86%E8%A7%92fov%E5%92%8C%E7%BA%B5%E6%A8%AA%E6%AF%94aspect-ratio)

这个部分代码如下：

```cpp
// fov 需要转换为弧度值
eye_fov *= MY_PI / 180;
float height = abs(zNear) * tan(eye_fov * 0.5f) * 2;
float width = height * aspect_ratio;
```

这里代码没有用 l、r、t、b 是因为 height = t - b，width = r - l，而作业 1 相机在做完视图变换后，位置已经在原点，所以 l+r = 0，t + b = 0。

所以正交投影矩阵可以简化为：
$$
\mathbf M_{ortho}=
\begin{bmatrix}
\frac{2}{w}&0&0&0\\
0&\frac{2}{h}&0&0\\
0&0&\frac{2}{n-f}&\frac{n+f}{f-n}\\
0&0&0&1
\end{bmatrix}
$$
而透视截锥体到正交长方体的变换为
$$
\mathbf M_{frustum}=
\begin{bmatrix}
n&0&0&0\\
0&n&0&0\\
0&0&n+f&-nf\\
0&0&1&0
\end{bmatrix}
$$
最后代码实现如下：

```cpp
Eigen::Matrix4f get_projection_matrix(float eye_fov, float aspect_ratio,
                                      float dNear, float dFar)
{
    Eigen::Matrix4f projection = Eigen::Matrix4f::Identity();

    // dNear and dFar are positive
    float zNear = -dNear, zFar = -dFar;

    // From perspective to orthographic projection
    Eigen::Matrix4f frustum;
    frustum << zNear, 0, 0, 0,
             0, zNear, 0, 0,
             0, 0, zNear+zFar, -zNear * zFar,
             0, 0, 1, 0;

    eye_fov *= MY_PI / 180;
    float height = abs(zNear) * tan(eye_fov * 0.5f) * 2;
    float width = height * aspect_ratio;

    // Orthographic projection
    Eigen::Matrix4f ortho;
    ortho << 2 / width, 0, 0,0,
             0, 2 / height, 0, 0,
             0, 0, 2 / (zNear - zFar), (zNear + zFar) / (zFar-zNear),
             0, 0, 0, 1;

    projection = ortho * frustum;

    return projection;
}
```

### 2.1 关于三角形上下颠倒的问题

这个问题是由于代码框架输入的 n，f（即 zNear 和 zFar）实际上是距离而不是我们推到矩阵时所用的坐标，所以我们需要为其加上负号。为了避免歧义，我已经将形参的 zNear 和 zFar 改为了 dNear 和 dFar。

```cpp
Eigen::Matrix4f get_projection_matrix(float eye_fov, float aspect_ratio,
                                      float dNear, float dFar)
{
    Eigen::Matrix4f projection = Eigen::Matrix4f::Identity();

    // dNear and dFar are positive
    float zNear = -dNear, zFar = -dFar;
```

## 3. 绕任意轴旋转

这个问题就要用到罗德里格旋转公式（Rodrigues’ rotation formula）。
$$
\mathbf R(\boldsymbol n,\alpha)=\cos(\alpha)\mathbf I+
(1-\cos\alpha)\boldsymbol{nn^{\mathbf T}}+
\sin\alpha
\underbrace{
\begin{bmatrix}
0&-n_z&n_y\\
n_z&0&-n_x\\
-n_y&n_x&0
\end{bmatrix}
}_{\mathbf N}
$$
需要注意的是该公式是基于 $3\times 3$ 矩阵的，所以最后我们需要讲计算结果转换为齐次坐标的 $4\times4$ 矩阵。

代码如下：

```cpp
Eigen::Matrix4f get_rotation(Vector3f axis, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
	
    // 单位化轴向量
    axis.normalize();

    Eigen::Matrix3f n;
    n << 0, -axis.z(), axis.y(),
         axis.z(), 0, -axis.x(),
         -axis.y(), axis.x(), 0;

    Eigen::Matrix3f rot3f = c * Eigen::Matrix3f::Identity() + (1 - c) * axis * axis.transpose() + s * n;

    Eigen::Matrix4f rot4f = Eigen::Matrix4f::Identity();

    rot4f.block<3, 3>(0, 0) = rot3f;

    return rot4f;
}
```

这里没有使用弧度转换是因为该函数是被 `get_model_matrix` 调用，而 `get_model_matrix` 已经转换过弧度了。

## 4. Bug：数组越界（Segmentfault 0xc0000005）

当绕某些轴旋转时（如 X 轴），会遇到数组越界的问题，导致程序崩溃。Debug 后发现问题出在 Rasterizer.cpp，`set_pixel` 函数中的判断语句。

```cpp
void rst::rasterizer::set_pixel(const Eigen::Vector3f& point, const Eigen::Vector3f& color)
{
    //old index: auto ind = point.y() + point.x() * width;
    if (point.x() < 0 || point.x() >= width ||
        point.y() < 0 || point.y() >= height) return;
    auto ind = (height-point.y())*width + point.x();
    frame_buf[ind] = color;
}
```

该函数的功能是判断像素点在不在投影范围内，如果在其中，就将改像素信息写入 `frame_buf` 中，否则跳过该像素。

frame_buf 是将二维像素信息用一维数组保存，大小为 700 x 700 即 490000。像素点坐标到数组序号的转换公式是

```cpp
auto ind = (height-point.y())*width + point.x();
```

如果按照判断条件，当出现如点 $(664, 0)$ 时，改点的判断为 `false`  从而按照公式计算出序号 `ind` = 490664，从而导致数组越界。

因此判断条件包含 y 为 0 的情况。改为，

```cpp
if (point.x() < 0 || point.x() >= width ||
    point.y() <= 0 || point.y() >= height) return;
```

## 5. 最终效果

绕向量 $(3, 3, 0)^\mathbf T$旋转：

<img src="https://img.ashechol.top/picgo/games101_hw1.gif" style="zoom:67%;" />

## 相关链接

笔记：[计算机图形学笔记(1)：变换](https://blog.ashechol.top/2023/01/04/computer%20graphic/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E7%AC%94%E8%AE%B0(1)%EF%BC%9A%E5%8F%98%E6%8D%A2/)

完整源码：[Github](https://github.com/Ashechol/Games101/tree/main/source/HW1)

