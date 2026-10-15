EIGRP 的**非等价负载均衡（Unequal-Cost Load Balancing）**，核心其实就两个东西：

> **`variance` 决定“允许多差的路径进来”**  
> 
> **Feasibility Condition（可行性条件）决定“这条路径有没有环路风险，能不能真的进来”**

这两个条件**必须同时满足**。

---

# `variance` 到底是什么意思？

假设：

```
最佳路径 Metric = 100
```

现在配置：

```
router eigrp 100
 variance 2
```

那么 EIGRP 允许：

```
100 × 2 = 200
```

也就是说：

> **只要一条备用路径的总 Metric ≤ 200，它就有机会进入负载均衡。**

例如：

| 路径  | Metric | 是否满足 variance 2 |
| --- | -----: | --------------- |
| R2  |    100 | ✅               |
| R3  |    120 | ✅               |
| R4  |    180 | ✅               |
| R5  |    200 | ✅               |
| R6  |    210 | ❌               |

但是这里有一个**非常重要的坑**：

> **满足 `variance` ≠ 一定可以负载均衡。**

还必须满足 **Feasibility Condition**。

#### 为什么还需要 Feasibility Condition？

这是 EIGRP 非等价负载均衡最容易考的地方。

EIGRP 要保证备用路径是**无环路的**。

核心判断：

> **备用路径的 RD（Reported Distance）必须 < 当前最佳路径的 FD（Feasible Distance）。**

也就是：

```text
RD < FD
```

如果满足：

```text
RD < FD
```

那么这条路径就是：

> **Feasible Successor（可行后继）**

只有这种路径才有资格参与 EIGRP 的非等价负载均衡。
最重要的判断流程

你以后看到 EIGRP 非等价负载均衡题目，直接按照这个顺序：

```text
             找最佳路径
                  ↓
          得到 Successor
                  ↓
              得到 FD
                  ↓
       ┌──────────┴──────────┐
       ↓                     ↓
   检查 RD < FD          检查 Metric
       ↓                     ↓
   Feasible Successor    Metric ≤ FD×variance
       ↓                     ↓
       └──────────┬──────────┘
                  ↓
          两个条件都满足
                  ↓
        进入 RIB / 参与负载均衡
```

所以一定记住：

> **非等价负载均衡 = Feasibility Condition + Variance**

---

# 一个特别经典的考试题

假设：

```text
最佳路径：
FD = 100

备用路径 A：
RD = 80
Metric = 150

备用路径 B：
RD = 120
Metric = 150
```

配置：

```cisco
router eigrp 100
 variance 2
```

先算：

```text
100 × 2 = 200
```

所以：

```text
A：150 ≤ 200 ✅
B：150 ≤ 200 ✅
```

看起来两个都符合 variance。

但是还要看 RD。

### 路径 A

```text
RD = 80
FD = 100

80 < 100
```

成立。

所以：

```text
A = Feasible Successor
```

### 路径 B

```text
RD = 120
FD = 100

120 < 100
```

不成立。

所以：

```text
B ≠ Feasible Successor
```

最终：

```text
A → 可以参与
B → 不可以参与
```

**即使你把 variance 调成 3、4、10，B 也不能因为 variance 变大而进入负载均衡。**

因为它失败的是：

```text
RD < FD
```

而不是：

```text
Metric ≤ FD × variance
```

Cisco 的官方示例也专门说明了这一点：一条路径即使落在 variance 范围内，如果不是 feasible successor，也不会用于负载均衡。([Cisco](https://www.cisco.com/c/en/us/support/docs/ip/enhanced-interior-gateway-routing-protocol-eigrp/13677-19.html?utm_source=chatgpt.com "How Does Unequal Cost Path Load Balancing (Variance) Work in IGRP and EIGRP - Cisco"))

---
流量是不是 50% / 50%？

**不是。**

这是另一个非常重要的细节。

假设：

```text
Path A = 100
Path B = 200
```

并且两条都满足条件。

EIGRP 默认使用：

```cisco
traffic-share balanced
```

进行基于 Metric 的流量分配。Cisco 文档说明，非等价路径的流量会按照路径 Metric 进行相应的比例分配。([Cisco](https://www.cisco.com/c/en/us/support/docs/ip/enhanced-interior-gateway-routing-protocol-eigrp/13677-19.html?utm_source=chatgpt.com "How Does Unequal Cost Path Load Balancing (Variance) Work in IGRP and EIGRP - Cisco"))

直观理解：

```text
Metric 越小
   ↓
路径越优
   ↓
承担的流量越多
```

例如：

```text
A = 100
B = 200
```

那么 A 应该承担更多流量，而不是：

```text
50% / 50%
```

---

# `maximum-paths` 也要注意

还有一个容易漏掉的东西：

```cisco
maximum-paths
```

它控制 EIGRP 最多允许多少条并行路径进入路由表。Cisco 当前 IOS XE 文档把 `variance` 和 `maximum-paths` 都列为 EIGRP 负载均衡相关配置。([Cisco](https://www.cisco.com/c/en/us/td/docs/routers/ios-xe/ip-routing/b-ip-routing/m_ire-enhanced-igrp.html?utm_source=chatgpt.com "IP Routing Configuration Guide - EIGRP [Support] - Cisco"))

例如：

```cisco
router eigrp 100
 maximum-paths 4
 variance 3
```

意思大致可以理解为：

```text
variance 3
    ↓
扩大允许进入的 Metric 范围

maximum-paths 4
    ↓
最多安装 4 条路径
```

所以这两个命令作用完全不同：

|命令|作用|
|---|---|
|`variance`|**允许多差的路径进入**|
|`maximum-paths`|**最多允许几条路径进入**|
|`traffic-share balanced`|**多条路径之间如何分配流量**|

---

