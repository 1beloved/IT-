# OSPF Type 1 / Type 2 LSA + SPF

## 一、先建立整个 OSPF 的逻辑

先不要急着背 LSA。

OSPF 的核心流程实际上就是：

```
邻居建立
   ↓
交换 LSA
   ↓
形成 LSDB
   ↓
LSDB 中保存整个区域的拓扑信息
   ↓
SPF（Dijkstra）
   ↓
计算最短路径
   ↓
RIB
   ↓
FIB
```

所以你可以把：

> **LSA = 描述网络的信息**

> **LSDB = 收集起来的所有 LSA**

> **SPF = 根据 LSDB 算路**

这是理解 OSPF 最重要的三个概念。

---

# 二、Type 1 LSA —— Router LSA

## 1. Type 1 是谁产生的？

**每一台 OSPF 路由器都会产生自己的 Type 1 LSA。**

例如：

```
R1 RID = 1.1.1.1
R2 RID = 2.2.2.2
R3 RID = 3.3.3.3
```

那么区域 0 中会有：

```
Type 1
 ├── R1 Router LSA
 ├── R2 Router LSA
 └── R3 Router LSA
```

---

## 2. Type 1 的三个关键字段

|字段|含义|
|---|---|
|Type|1|
|Link State ID|Router ID|
|Advertising Router|产生这个 LSA 的 Router ID|

例如 R1：

```
Type:               1
Link State ID:      1.1.1.1
Advertising Router: 1.1.1.1
```

### CCNP 必背

> **Type 1 → Router LSA → 每台 Router 产生 → LSID = RID**

---

# 三、Type 1 到底描述什么？

Type 1 描述：

> **“我这台 Router 在这个 Area 里面有哪些链路，以及这些链路是什么状态。”**

例如：

```
        R2
        |
        |
R1 -----+----- R3
```

R1 会在自己的 Type 1 LSA 中描述：

```
R1：
 ├── 到 R2 的链路
 └── 到 R3 的链路
```

R2 也会产生自己的 Type 1：

```
R2：
 ├── 到 R1 的链路
 └── 到 R3 的链路
```

因此：

> **每台 Router 描述自己，而不是替别人描述。**

这个思想非常重要。

---

# 四、Type 1 中的链路类型

这里你原笔记有一个需要纠正的地方。

你写：

> 传输链路 = 有 OSPF 邻居  
> Stub = 无 OSPF 邻居

**这个记忆方式太粗糙，考试容易出问题。**

Cisco OSPF Router LSA 常见的 Link Type 有：

```
1 = Point-to-Point
2 = Transit Network
3 = Stub Network
4 = Virtual Link
```

你现在主要学习：

```
Transit Network
Stub Network
```

---

# 五、Transit Network

典型场景：

```
R1
 |
 |
 +------+
        |
        | Ethernet
        |
 +------+
 |
R2
```

这是一个多路访问网络。

假设：

```
12.1.1.0/24
```

R1：

```
12.1.1.1
```

R2：

```
12.1.1.2
```

DR：

```
12.1.1.1
```

假设 R1 成为 DR。

那么 R2 的 Type 1 中会有类似：

```
Link Type: Transit Network

Link ID:
12.1.1.1

Link Data:
12.1.1.2

Metric:
10
```

这里：

### Link ID

```
DR 的接口 IP
```

### Link Data

```
本路由器在这个网络上的接口 IP
```

---

# 六、Type 2 LSA —— Network LSA

这就是你这部分真正需要和 Type 1 配合理解的地方。

## 1. Type 2 是谁产生？

**DR 产生 Type 2 LSA。**

注意：

> **不是所有 Router 都产生 Type 2。**

例如：

```
        R1
         |
         |
R2 ------+------ R3
         |
        DR
```

DR 负责代表这个多路访问网络产生：

```
Type 2 Network LSA
```

---

# 七、Type 2 的三个关键字段

| 字段                 | 含义             |
| ------------------ | -------------- |
| Type               | 2              |
| Link State ID      | DR 接口 IP       |
| Advertising Router | DR 的 Router ID |

例如：

```
Type:               2
Link State ID:      12.1.1.1
Advertising Router: 1.1.1.1
```

注意两个东西不要混：

### Link State ID

```
DR接口IP
```

### Advertising Router

```
DR的Router ID
```

这是非常经典的考试陷阱。

---

# 八、Type 2 里面有什么？

Type 2 主要描述：

```
这个 Transit Network 上有哪些 OSPF Router
```

例如：

```
12.1.1.0/24

       DR
       |
  +----+----+
  |         |
 R1        R2
```

Type 2 可以告诉其他 Router：

```
Network Mask:
255.255.255.0

Attached Routers:
1.1.1.1
2.2.2.2
```

所以 Type 2 的核心思想：

> **“这个共享网络上有哪些 Router，以及这个网络的掩码是多少。”**

---

# 九、Type 1 + Type 2 是怎么配合的？

这是你现在这节课**最应该搞懂的地方。**

假设：

```
        R1
        |
        |
   12.1.1.0/24
        |
        |
        R2
```

在 Ethernet 多路访问网络中：

### Type 1

Router LSA 描述：

```
R1 → Transit Network
R2 → Transit Network
```

也就是：

> **Router 自己连接到了这个 Transit Network。**

### Type 2

DR 产生 Network LSA：

```
12.1.1.0/24
```

并记录：

```
R1
R2
```

也就是：

> **这个 Network 上有哪些 Router。**

因此：

```
Type 1
   ↓
描述 Router 的连接

Type 2
   ↓
描述共享 Network
```

两者结合起来，OSPF 才能完整描述这个网络。

---

# 十、一个非常重要的纠正

你原文中有一句：

> “通过一类LSA的传输链路和二类LSA的末节链路，可完整构建OSPF拓扑图”

❌ **这个说法不要记。**

因为：

> **Type 2 不是“Type 1 的末节链路”。**

Type 1 中的：

```
Stub Network
```

和：

```
Type 2 Network LSA
```

是两个完全不同的概念。

一定分开。

---

# 十一、Stub Network 到底是什么？

这是你目前最容易混淆的地方。

不要简单记：

> Stub = 没有邻居。

更准确地理解：

> **Stub Network 是 Router LSA 中用来描述一个非 Transit 类型的网络/前缀。**

例如：

```
        R3
        |
        |
     Loopback0
     3.3.3.3/32
```

R3 的 Router LSA 可以描述：

```
Link Type: Stub

Link ID:
3.3.3.3

Link Data:
255.255.255.255

Metric:
1
```

于是其他 Router 可以通过 OSPF 学到：

```
3.3.3.3/32
```

---

# 十二、所以 Type 1 中你可以这样理解

```
             Type 1
                |
       +--------+--------+
       |                 |
   Transit            Stub
       |                 |
描述拓扑连接          描述前缀/网络
       |
参与拓扑计算
```

而：

```
Type 2
   |
   ↓
描述 Transit Network
   |
   ↓
DR 产生
```

---

# 十三、LSDB 到底是什么？

假设：

```
R1
R2
R3
```

全部在 Area 0。

它们会互相泛洪 LSA。

最终：

```
R1 LSDB ≈ R2 LSDB ≈ R3 LSDB
```

也就是说：

> **同一个 Area 内，正常收敛后，所有 Router 应该拥有相同的 LSDB。**

但是：

### Age 可以不同

因为每台设备收到 LSA 的时间可能略有不同。

所以不要死记：

> 所有字段必须 100% 一样。

更准确：

> **LSA 内容应保持一致，Age 等动态时间字段可以不同。**

---

# 十四、SPF 到底怎么算？

这是你后面 CCNP 很重要的一块。

假设：

```
        R2
       /  \
      /    \
    R1------R3
```

假设：

```
R1 → R2 = 10
R1 → R3 = 10
R2 → R3 = 10
```

R1 想去 R3。

有两条路：

```
路径1：

R1 → R3
10
```

```
路径2：

R1 → R2 → R3
10 + 10 = 20
```

所以：

```
R1 → R3
```

胜出。

---

# 十五、如果修改接口 Cost

例如：

```
R1 → R3 = 20
```

那么：

```
R1 → R3
20
```

而：

```
R1 → R2 → R3
10 + 10 = 20
```

两条路径：

```
20 = 20
```

那么就可能形成：

> **ECMP（Equal-Cost Multi-Path）等价负载均衡。**

如果：

```
R1 → R3 = 5
```

那么：

```
R1 → R3 = 5
R1 → R2 → R3 = 20
```

选择：

```
R1 → R3
```

---

# 十六、这里还有一个你必须纠正的概念

你原笔记写：

> “直连路由不参与 OSPF 计算。”

这句话**不够准确**。

例如：

```
R1 G0/0
12.1.1.1/24
```

这个接口是直连网络：

```
12.1.1.0/24
```

确实：

```
C 12.1.1.0/24
```

本身不是通过 OSPF 学来的。

但是：

> **这个接口对应的 OSPF 链路信息会被写入 Router LSA，并可能参与 SPF 的拓扑计算。**

所以正确理解应该是：

### 直连路由本身

```
C 12.1.1.0/24
```

不是 OSPF 学习的。

但是：

### OSPF 接口

```
G0/0
```

可能形成：

```
Router LSA
```

并参与 OSPF 拓扑计算。

---

# 十七、OSPF Cost 怎么算？

Cisco 默认参考带宽：

```
100 Mbps
```

公式：

```
Cost = Reference Bandwidth / Interface Bandwidth
```

例如：

```
100 Mbps / 100 Mbps = 1
```

```
100 Mbps / 10 Mbps = 10
```

所以：

```
100M → cost 1
10M  → cost 10
```

而 Loopback 通常：

```
cost 1
```

所以你实验里面：

```
R1 → R3
10

R3 Loopback
1
```

最终：

```
到 3.3.3.3/32

10 + 1
= 11
```

因此：

```
O 3.3.3.3/32 [110/11]
```

这里：

```
110
↑
Administrative Distance

11
↑
OSPF metric / cost
```

---

# 十八、你这节课真正应该背的表

| 内容                 | Type 1                | Type 2             |
| ------------------ | --------------------- | ------------------ |
| 名称                 | Router LSA            | Network LSA        |
| 谁产生                | 每台 Router             | DR                 |
| Type               | 1                     | 2                  |
| LSID               | Router ID             | DR 接口 IP           |
| Advertising Router | Router ID             | DR 的 Router ID     |
| 作用                 | 描述 Router 在 Area 内的链路 | 描述 Transit Network |
| 是否描述 Router        | ✅                     | Attached Routers   |
| 是否描述 Network Mask  | 某些链路类型中涉及             | ✅                  |
| 泛洪范围               | Area 内                | Area 内             |
| SPF                | 提供拓扑信息                | 协助描述多路访问网络         |

---

# 十九、CCNP 考试最容易考你的几个坑

### 坑 1

**谁产生 Type 1？**

```
每台 OSPF Router
```

不是 DR。

---

### 坑 2

**谁产生 Type 2？**

```
DR
```

不是所有 Router。

---

### 坑 3

**Type 1 的 LSID 是什么？**

```
Router ID
```

---

### 坑 4

**Type 2 的 LSID 是什么？**

```
DR 接口 IP
```

---

### 坑 5

**Type 2 的 Advertising Router 是什么？**

```
DR 的 Router ID
```

注意：

```
LSID ≠ Advertising Router
```

---

### 坑 6

**Type 2 是不是 DR 自己的虚拟 Router？**

❌ 不是。

DR 是一个真实的 OSPF Router。

Type 2 是：

> **DR 为 Transit Network 产生的 Network LSA。**

---

### 坑 7

**Stub Network = 没有邻居？**

❌ 不建议这么背。

应该记：

> **Stub Link 是 Router LSA 中描述非 Transit 网络/前缀的一种 Link Type。**

---

### 坑 8

**OSPF 是不是每台 Router 都用同一个 SPF？**

❌ 不是。

每台 Router：

```
以自己为 Root
```

独立执行：

```
Dijkstra SPF
```

因此：

```
R1 → SPF
R2 → SPF
R3 → SPF
```

各自计算。

---

# 二十、把整个知识点压缩成一张图

```
                 OSPF
                   │
              LSA 泛洪
                   │
                 LSDB
                   │
          ┌────────┴────────┐
          │                 │
       Type 1             Type 2
     Router LSA         Network LSA
          │                 │
     每台Router             DR
          │                 │
    描述自己的链路       描述Transit Network
          │                 │
          └────────┬────────┘
                   │
                  SPF
                   │
              Dijkstra
                   │
          最短路径树 SPF Tree
                   │
                  RIB
                   │
                  FIB
```