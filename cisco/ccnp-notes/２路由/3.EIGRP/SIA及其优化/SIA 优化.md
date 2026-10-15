## 一SIA 的核心机制

EIGRP 路径失效时，若 DUAL 找不到可行后继者（Feasible Successor），路由进入 **Active 状态**：

```text
路由失效
   ↓
没有 Feasible Successor
   ↓
路由进入 Active
   ↓
向邻居发送 Query
   ↓
邻居继续查询自己的邻居
   ↓
Query 扩散
   ↓
等待 Reply
   ↓
长时间收不到回复
   ↓
SIA（Stuck-In-Active）
```

**关键认知**：SIA 不是“查询扩散就一定发生”，而是路由处于 Active 后，某个邻居迟迟没有返回 Reply，最终超过 SIA 计时器导致的问题。

**防 SIA 的核心**：

> **限制 Query 的传播范围 + 减少需要等待 Query Reply 的邻居数量。**

---

## 二、路由汇总：形成 Query Boundary

### 工作原理

```text
        Core
         R1
         |
         |
         R2
      汇总边界
    /    |    \
  R3    R4    R5
172.30.1.0/24
172.30.2.0/24
172.30.3.0/24
```

R2 向 R1 只通告汇总路由：

```text
172.30.0.0/16
```

而不是具体前缀：

```text
172.30.1.0/24
172.30.2.0/24
172.30.3.0/24
```

R1 的路由表中只有：

```text
D 172.30.0.0/16
```

当 `172.30.1.0/24` 发生故障时：

```text
R2 ── Query ──> R1
```

R1 并不知道 `172.30.1.0/24` 这个具体前缀，因此**不会继续针对该前缀向其他邻居扩散 Query**。

### 精确表述

> **路由汇总通过隐藏下游具体前缀，在汇总边界形成 Query Boundary。**

记忆图示：

```text
具体路由 172.30.1.0/24
       ↓
     R2
       ↓
   汇总边界
       ↓
汇总路由 172.30.0.0/16
       ↓
     R1
```

**R1 不需要知道下面到底有多少个 /24。**

---

## 三、EIGRP Stub：限制 Query 向 Stub 方向扩散

### 常见误解修正

Stub **不是**说“核心路由器认为 Stub 不可达”。

正确表述是：

> **核心路由器知道这个邻居是 Stub，因此在发送 Query 时不会向 Stub 邻居发送 Query。**

### 工作机制

```text
             R1
           /    \
          R2    R3
          |
        Stub R4
```

R4 告诉 R2：“我是 EIGRP Stub”。

R2 某条路由进入 Active 需要查询邻居时：

```text
R2 ── Query ──> R1
R2 ── Query ──> R3
R2 ── X ──> R4        ← 不会向 R4 发送 Query
```

原因：R2 已知 R4 是 Stub，不会作为其他路由的 Transit 路径，因此 R4 不可能成为这次 Query 的有效下游查询者。

### 精确表述

> **EIGRP Stub 通过限制邻居向 Stub 发送 Query，阻止 Query 向 Stub 方向扩散。**

### Query 扩散对比

**普通 EIGRP Router**：

```text
       R1
      /  \
     R2  R3
     |
     R4
     |
     R5

Query 可以继续：R1 → R2 → R4 → R5
```

**R4 为 Stub 时**：

```text
       R1
      /
     R2
     |
    R4
   Stub

Query：R1 → R2
            ↓
            X
           R4
```

R2 不会把 Query 发给 R4，Stub 形成另一种 **Query Boundary**。

---

## 四、`eigrp stub` 的选项

### 默认行为

```cisco
router eigrp 100
 eigrp stub
```

默认等价于：

```cisco
eigrp stub connected summary
```

即 Stub 默认可以向邻居通告 **Connected** 和 **Summary**。

### 常见选项

```text
eigrp stub
     │
     ├── connected      直连路由
     ├── static         静态路由
     ├── summary        汇总路由
     ├── redistributed  重分发进来的路由
     ├── receive-only   不发布任何路由
     └── leak-map       精确放行特定路由
```

示例：

```cisco
eigrp stub static
eigrp stub redistributed
```

### `receive-only` 特别理解

```cisco
eigrp stub receive-only
```

含义：

> **不向 EIGRP 邻居发布任何路由，但仍可以从邻居接收 EIGRP 路由。**

对比：

```text
普通 Stub：可以发布允许的路由
Receive-only：不发布路由
```

---

## 五、双归属 Stub：重点考点

```text
             Core
            /    \
           R1    R2
            \    /
             R3
```

R3 是分支，同时连接 R1、R2，且被配置成 Stub。

此时 R3 **不会把从 R1 学到的 EIGRP 路由再通过 R2 通告出去**：

```text
R1
 ↓
R3
 ↓
 R2      ← 这种 Transit 行为不是 Stub 的设计目标
```

**关键区别**：

> **Stub 不是“告诉别人我只能有一条链路”，而是告诉邻居“不要把我当作 Transit 路由器”。**

---

## 六、`leak-map`：Stub 的例外机制

用于解决：

> **“我想保持 Stub 的安全特性，但又想允许少量特定路由通过。”**

```text
             R1
            /  \
           /    \
          R3
           \
            R2
```

R3 是 Stub，但某些特殊前缀确实需要被允许通告：

```cisco
eigrp stub leak-map NAME
```

通过 route-map 精确控制哪些路由可以被“泄漏”。

记忆链：

```text
Stub
 ↓
默认限制 Transit
 ↓
需要特殊放行
 ↓
leak-map
 ↓
只允许指定路由
```

---

## 七、CCNP 记忆总表

| 技术 | 核心作用 | 如何限制 Query |
|---|---|---|
| **Route Summarization** | 隐藏下游具体前缀 | 在汇总边界形成 Query Boundary |
| **EIGRP Stub** | 告诉邻居自己不是 Transit | 邻居不向 Stub 发送 Query |
| **Stub + Summary** | 两者结合 | 同时减少 Query 的传播范围和数量 |
| **Leak-map** | Stub 的特殊例外 | 精确允许少量路由通告 |

---

## 八、最重要的一句话

> **EIGRP 防 SIA 的核心不是“让路由永远不会进入 Active”，而是尽量限制 Active 路由产生的 Query 扩散范围，并减少需要等待 Reply 的邻居。**

---

## 九、术语修正提醒

作为帮助记忆的比喻可以保留：

> ~~汇总从逻辑上切断查询，Stub 从物理上切断查询~~

但考试笔记中建议使用 Cisco 技术表述：

> **路由汇总通过隐藏具体前缀形成 Query Boundary；EIGRP Stub 通过限制邻居向 Stub 发送 Query，阻止 Query 向 Stub 方向扩散。**

---

整理完毕。整体结构现在是：**机制 → 汇总 → Stub → 选项 → 双归属 → leak-map → 总表 → 核心句 → 术语修正**，可以直接作为 CCNP 复习材料使用。