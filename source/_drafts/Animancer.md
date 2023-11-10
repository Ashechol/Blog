# Animancer 个人笔记

## 1. 什么是 Animancer

### 1.1 Macanim

通常会情况下，在 Unity 当我们需要按照逻辑播放角色动画的时候，会使用 `Animator` 组件，并且在 `Animator Controller` 中设计好动画状态机，之后在程序中传参给动画状态机驱动挂在了 `Animator` 组件的角色在不同状态下播放不同的动画。`Animator` + `Animator Controller` 也被称作 Unity 的 `Macanim` 系统。

当我们一个角色的美术动画资源较少的时候，这个系统可以帮助我们快速其直观的设计动画之间的转换。然而现今的游戏，特别是 ACT 这个类别，一个人物的动画数量是相当庞大的，他们之间的转换关系也十分复杂。如果还是使用 `Macanim` 系统，会遇到以下几个瓶颈：

* 状态机设计需要花费大量时间，不论这个任务是交给策划、美术还是程序。
* 越庞大，转换关系越复杂的状态机越不利于维护和 Debug。
* 动画状态机逻辑与程序实现逻辑的重复。
* 不利于协同开发。

### 1.2 Playable API

`Playable API` 是 Unity 官方提供的一个通过组织和评估树状结构（称为 `PlayableGraph`）中的数据源来创建工具、效果或其他游戏机制的方法。`PlayableGraph` 允许混合、融合和修改多个数据源，并通过单个输出播放它们。

简单来说，开发者可以通过这个 API 定制化自己的一套动画系统，不再使用 `Macanim` 。

### 1.3 Animancer

Animancer 就是在 Playable API 这个基础上构建的一套第三方的动画系统（轮子）。它的特点主要有：

* 完全不用依赖 `Animator Controller`
* 可以直接通过代码自由控制动画的切换、过度、混合等等属性
* 可以动态的加载和卸载 `Animation Clip`

> 更多特点可以参考官方文档：https://kybernetik.com.au/animancer/docs/introduction/features

## 2. 简单的动画播放

首先，角色人需要挂载 Animator 组件，**注意 Animator Controller  一栏必须是空的** 。之后需要挂载 `Animancer Component` （可以不挂在角色模型上面，不过得手动设置 Animator）。

<img src="https://img.ashechol.top/picgo/animancer_setting_01.png" style="zoom: 80%;" />

这样最基本的配置就完成了。

接下来创建一个管理动画片段资源和调用 `Animancer Component` 播放动画的脚本。

```c#
public class AnimancerTest : MonoBehaviour
{
    private AnimancerComponent _animancer;
    [SerializeField] private AnimationClip _clip;

    private void Awake()
    {
        _animancer = GetComponent<AnimancerComponent>();
    }

    private void Start()
    {
        _animancer.Play(_clip); 
    }
}
```

点击 Play 即可看到效果。

<img src="https://img.ashechol.top/picgo/animancer_test_01.gif" style="zoom: 33%;" />
