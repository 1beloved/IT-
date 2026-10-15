对，你这张笔记的**整体思路是对的**，但有两处需要你改一下，否则后面学 MST 容易混淆。

### 1. 你的 STP Cost 理解是对的

核心就是：

> **接口速率越高 → Cost 越小。**

例如 Cisco 常见的 **Short Path Cost**：

|     链路带宽 | Cost |
| -------: | ---: |
|  10 Mbps |  100 |
| 100 Mbps |   19 |
|   1 Gbps |    4 |
|  10 Gbps |    2 |

你图片里的最后一个：

```text
1000 Mbit   2
```

这里应该是 **10000 Mbit（10 Gbps）**，不是 1000 Mbit。

---

### 2. STP 计算的是“累计 Path Cost”

这个你图片里的描述也对。

比如：

```text
SW1 ──10G── SW2 ──1G── SW3
```

假设使用 Short：

```text
SW1
 ↓
10G cost = 2
 ↓
SW2
 ↓
1G cost = 4
 ↓
SW3
```

那么：

```text
SW3 → SW1 的 Root Path Cost
= 4 + 2
= 6
```

所以 STP 选择路径时，本质上就是：

> **从自己到 Root Bridge，比较不同路径的累计 Path Cost，选择 Cost 最低的路径。**

---

# 3. 你笔记里最需要修改的是这一句

你写的是：

> `short 1998的802.1D标准，而MST多实例生成树则为long则为802.1t`

这里不要这么记。

更准确地记：

```text
802.1D
    ↓
传统 STP
    ↓
Short Path Cost

802.1t
    ↓
扩展/增强 Path Cost
    ↓
Long Path Cost
```

而：

```text
802.1s
    ↓
MSTP
```

**MSTP 并不等于“802.1t”。**

它们是不同的标准：

```text
802.1D → STP
802.1w → RSTP
802.1s → MSTP
802.1t → Path Cost 扩展
```

这几个编号一定要分开。

---

# 4. 那为什么 MST 经常看到 Long Cost？

因为 MST 为了支持越来越高速的网络，通常采用 **Long Path Cost**。

Cisco 可以通过：

```cisco
Switch(config)# spanning-tree pathcost method ?
  long
  short
```

选择：

```cisco
spanning-tree pathcost method long
```

或者：

```cisco
spanning-tree pathcost method short
```

### Short

```text
10M     100
100M    19
1G      4
10G     2
```

### Long

大致是：

```text
10M      2,000,000
100M       200,000
1G          20,000
10G          2,000
100G           200
```

所以 Long 的核心目的就是：

> **给高速率接口提供更大的 Cost 数值空间。**

---

# 5. 你现在学 MST，要特别注意一个点

**Cost 和 MSTI 是两个维度。**

比如：

```text
             SW1
            /   \
         G0/1   G0/2
          /       \
        SW2       SW3
```

假设：

```text
G0/1 = 1G
G0/2 = 1G
```

那么默认：

```text
G0/1 cost = 4
G0/2 cost = 4
```

这跟是不是 MSTI 1、MSTI 2 **没有直接关系**。

但是你可以针对不同 MSTI 手工修改：

```cisco
interface g0/1
 spanning-tree mst 1 cost 10
 spanning-tree mst 2 cost 50
```

于是：

```text
G0/1

MSTI 1 → Cost 10
MSTI 2 → Cost 50
```

这样才能实现：

```text
MSTI 1 → 走路径 A
MSTI 2 → 走路径 B
```

这才是 MST **利用不同 Instance 做负载分担**的核心。

---

### 你这页笔记建议最终改成：

```text
STP Path Cost
│
├── 根据接口带宽决定
│
├── 带宽越高 → Cost 越低
│
├── Short Path Cost
│     ├── 10M   → 100
│     ├── 100M  → 19
│     ├── 1G    → 4
│     └── 10G   → 2
│
└── Long Path Cost
      └── 为高速接口提供更大的 Cost 范围

标准：
802.1D → STP
802.1w → RSTP
802.1s → MSTP
802.1t → Extended/Long Path Cost
```

**最重要的纠正：不要记“MST = 802.1t”。MST 是 802.1s；Long Path Cost 是 802.1t 相关的扩展。**