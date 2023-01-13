---
title: test
date: 2021/1/1
math: true
mermaid: true
---



$$
\mathbf M_{persp}=\mathbf M_{ortho}\mathbf M_{persp\to ortho}
$$

```mermaid
graph LR
A(相机视锥)--透视投影变换-->B(裁剪空间)--齐次/透视除法-->C(NDC)--视口变换-->D(屏幕空间)
```

