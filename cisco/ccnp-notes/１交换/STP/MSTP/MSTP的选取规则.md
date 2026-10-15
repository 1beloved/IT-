**MST 有一个非常重要的变化：端口角色的选举逻辑和 PVST/RSTP 的基本原理一样，但 MST 是“按实例”进行选举的。**

你可以把它理解成：

> **MST = RSTP 的机制 + 多个 MST Instance。**

---

## 1. 端口角色：基本一样

MST 中主要还是：

- **Root Port（RP）**
    
- **Designated Port（DP）**
    
- **Alternate Port**
    
- **Backup Port**
    

和你之前学的 RSTP/PVST+ 的思路基本一致。

例如：

```text
             SW1
            Root
           /    \
         SW2----SW3
```

SW1 是 Root：

```text
SW1
G0/1 ── DP
G0/2 ── DP

SW2
连接 SW1 ── RP

SW3
连接 SW1 ── RP
```

SW2 和 SW3 之间因为存在环路，其中一个方向会出现：

```text
Alternate
```

---

# 2. 选 Root Bridge 的规则也一样

首先选：

> **最小 Bridge ID**

Bridge ID：

```text
Priority + MAC
```

所以：

```text
最低 Priority
      ↓
如果相同
      ↓
最低 MAC
      ↓
Root Bridge
```

例如：

```text
SW1 priority 4096
SW2 priority 8192
SW3 priority 8192
```

那么：

```text
SW1 = Root
```

这个和 PVST 基本一致。

---

# 3. RP 的选举规则也基本一样

一个非 Root Switch 要选择自己的 Root Port。

核心就是比较：

```text
1. 最低 Root Path Cost
2. 最低发送方 Bridge ID
3. 最低发送方 Port ID
```

也就是你之前 PVST 学的：

> **谁到 Root 的路径最好，谁成为 RP。**

例如：

```text
             SW1
              |
             10G
              |
             SW2
```

SW2 到 SW1 的接口就很可能成为：

```text
Root Port
```

---

# 4. DP 的逻辑也一样

一条链路两边都不能同时成为 RP。

所以要决定：

> **谁负责转发这一段链路？**

胜者成为：

```text
Designated Port
```

失败的一侧在 RSTP/MST 中可能成为：

```text
Alternate Port
```

---

# 5. ⚠️ 但 MST 和 PVST 最大的区别在这里

PVST：

```text
VLAN 10 → 一棵 STP
VLAN 20 → 一棵 STP
VLAN 30 → 一棵 STP
VLAN 40 → 一棵 STP
```

所以每个 VLAN 都可以有自己的 Root。

例如：

```text
VLAN 10 → SW1 Root
VLAN 20 → SW2 Root
VLAN 30 → SW3 Root
```

---

MST：

```text
VLAN 10
VLAN 20
      ↓
    MSTI 1
      ↓
   一棵树

VLAN 30
VLAN 40
      ↓
    MSTI 2
      ↓
   一棵树
```

所以：

> **MST 是按照 MST Instance 来进行 STP 计算，而不是每个 VLAN 单独计算。**

---

# 6. 这就是 MST 最重要的概念

假设：

```text
MSTI 1
VLAN 10,20

MSTI 2
VLAN 30,40
```

那么实际上：

```text
VLAN 10 ─┐
         ├── MSTI 1 ── 一套 STP
VLAN 20 ─┘

VLAN 30 ─┐
         ├── MSTI 2 ── 一套 STP
VLAN 40 ─┘
```

因此你看到：

```text
MSTI 1:
Root = SW1

MSTI 2:
Root = SW2
```

是完全正常的。

于是同一个物理端口：

```text
G0/1
```

可能：

```text
MSTI 1 → DP
MSTI 2 → RP
```

**这就是 MST 非常重要的地方。**

---

# 7. 你可以这样对比

||PVST/PVST+|MST|
|---|---|---|
|STP计算单位|VLAN|MST Instance|
|Root Bridge|每 VLAN 一个|每 MSTI 一个|
|RP|有|有|
|DP|有|有|
|Alternate|RSTP/PVST+有|有|
|Root选举|Bridge ID|Bridge ID|
|RP选举|Path Cost等|Path Cost等|
|DP选举|BPDU比较|BPDU比较|
|核心选举逻辑|相同|相同|

---

## 8. CCNP考试你就记这一句话

> **MST 的端口角色和选举规则基本继承 RSTP，但 STP 拓扑计算是以 MST Instance 为单位，而不是以 VLAN 为单位。**

所以你之前学的：

```text
Root Bridge
↓
Root Port
↓
Designated Port
↓
Alternate Port
```

**不用重新学一套。**

你真正需要重点理解的新东西是：

```text
VLAN
 ↓
MSTI
 ↓
MST Region
 ↓
CIST / IST
 ↓
不同 MSTI 可以有不同 Root
 ↓
同一个物理端口在不同 MSTI 中可以拥有不同角色
```

尤其是最后这一点，**非常容易出 CCNP 选择题。**