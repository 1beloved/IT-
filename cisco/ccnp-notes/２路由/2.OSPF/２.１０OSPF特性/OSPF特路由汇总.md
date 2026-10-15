# 一、OSPF 路由汇总（Route Summarization）

## 1. 为什么需要 OSPF 汇总？

假设网络中存在：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
```

如果全部作为明细路由传播：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
```

可以汇总成：

```text
192.168.0.0/21
```

核心目的：

> **用一条汇总前缀代替多条明细前缀，减少路由表规模、减少路由传播，并降低拓扑变化造成的影响。**

---

# 2. OSPF 中两种重要的汇总

必须区分：

| 汇总类型    | 配置位置 | 汇总对象      | 典型命令              |
| ------- | ---- | --------- | ----------------- |
| ABR 汇总  | ABR  | 区域内/区域间路由 | `area X range`    |
| ASBR 汇总 | ASBR | 外部路由      | `summary-address` |

记忆：

> **ABR → Area Range**  
> **ASBR → Summary Address**

---

# 3. 实验拓扑

```text
    Area 0       ABR       Area 1

     R1 -------- R2 -------- R3
   12.1.1.0/24             23.1.1.0/24
      |                         |
   G0/0                      G0/0
                           Loopback
```

设备：

```text
R1
R2
R3
```

区域：

```text
R1 G0/0 → Area 0
R2 G0/0 → Area 0
R2 G0/1 → Area 1
R3 G0/0 → Area 1
```

IP：

```text
R1 G0/0 = 12.1.1.1/24
R2 G0/0 = 12.1.1.2/24
R2 G0/1 = 23.1.1.2/24
R3 G0/0 = 23.1.1.3/24
```

因此：

```text
R1 —— Area 0 —— R2 —— Area 1 —— R3
                ↑
                ABR
```

R2 同时连接 Area 0 和 Area 1，因此：

> **R2 是 ABR（Area Border Router）。**

---

# 4. OSPF 基础配置

## R1

```cisco
hostname R1

interface g0/0
 ip address 12.1.1.1 255.255.255.0
 ip ospf 110 area 0
 no shutdown
```

## R2

```cisco
hostname R2

interface g0/0
 ip address 12.1.1.2 255.255.255.0
 ip ospf 110 area 0
 no shutdown

interface g0/1
 ip address 23.1.1.2 255.255.255.0
 ip ospf 110 area 1
 no shutdown
```

## R3

```cisco
hostname R3

interface g0/0
 ip address 23.1.1.3 255.255.255.0
 ip ospf 110 area 1
 no shutdown
```

验证：

```cisco
show ip ospf neighbor
```

应该形成：

```text
R1 ←→ R2    Area 0
R2 ←→ R3    Area 1
```

---

# 5. Loopback 模拟业务网段

例如在 R3 上：

```cisco
interface loopback0
 ip address 192.168.0.1 255.255.255.255
 ip ospf 110 area 1

interface loopback1
 ip address 192.168.1.1 255.255.255.255
 ip ospf 110 area 1

interface loopback2
 ip address 192.168.2.1 255.255.255.255
 ip ospf 110 area 1

interface loopback3
 ip address 192.168.3.1 255.255.255.255
 ip ospf 110 area 1

interface loopback4
 ip address 192.168.4.1 255.255.255.255
 ip ospf 110 area 1
```

这些都是：

```text
Area 1 内部路由
```

R2 作为 ABR，需要把 Area 1 的路由传播到 Area 0。

---

# 6. 手工计算汇总地址

需要汇总：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
```

最小：

```text
192.168.0.1
```

最大：

```text
192.168.4.1
```

第三个字节：

```text
0 = 00000000
4 = 00000100
```

共同前缀：

```text
00000
```

前两个字节完全相同：

```text
8 + 8
```

第三个字节有 5 位相同：

```text
5
```

所以：

```text
8 + 8 + 5 = 21
```

汇总：

```text
192.168.0.0/21
```

掩码：

```text
255.255.248.0
```

范围：

```text
192.168.0.0
        ↓
192.168.7.255
```

因此：

```text
192.168.0.0/21
```

可以覆盖：

```text
192.168.0.0 ～ 192.168.7.255
```

---

# 7. ABR 路由汇总

## 核心概念

ABR 负责连接不同 OSPF Area。

例如：

```text
Area 1
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
       ↓
      R2
      ABR
       ↓
Area 0
192.168.0.0/21
```

目的：

> **Area 0 不需要知道 Area 1 中每一条明细前缀，只需要知道汇总前缀。**

---

# 8. Cisco ABR 汇总命令

在 R2：

```cisco
router ospf 110
 area 1 range 192.168.0.0 255.255.248.0
```

注意：

> `area 1 range` 配置在 ABR 上。

因为 R2 是：

```text
Area 0 ←→ Area 1
```

所以 R2 可以对 Area 1 的路由进行汇总。

---

# 9. ABR 汇总之后发生什么？

汇总之前：

```text
R3
├── 192.168.0.1/32
├── 192.168.1.1/32
├── 192.168.2.1/32
├── 192.168.3.1/32
└── 192.168.4.1/32
       ↓
      R2
       ↓
Area 0 得到多条明细路由
```

汇总之后：

```text
R3
├── 192.168.0.1/32
├── 192.168.1.1/32
├── 192.168.2.1/32
├── 192.168.3.1/32
└── 192.168.4.1/32
       ↓
      R2
       ↓
192.168.0.0/21
```

因此 Area 0 侧只需要处理：

```text
192.168.0.0/21
```

---

# 10. ABR 汇总的一个重要特点

汇总并不是简单地“把 R3 的明细路由删除”。

真正理解：

> **汇总主要控制的是跨区域传播的信息。**

Area 1 内部仍然可以存在：

```text
192.168.0.1/32
192.168.1.1/32
...
```

而其他区域通过 ABR 看到的是汇总后的前缀。

---

# 11. 汇总路由的生成条件

一个非常重要的考试点：

> **只有被汇总的明细路由仍然存在时，ABR 才能产生相应的汇总路由。**

例如：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
```

全部消失后：

```text
192.168.0.0/21
```

也可能随之消失。

所以：

> **汇总路由不是无条件永久存在的。**

---

# 12. 汇总对路由震荡的意义

假设 Area 1：

```text
192.168.1.1/32
```

不停 Up/Down。

如果没有汇总：

```text
明细路由变化
      ↓
跨区域传播
      ↓
其他区域受到影响
```

如果使用汇总：

```text
Area 1 内部明细变化
      ↓
ABR
      ↓
Area 0 仍然看到 192.168.0.0/21
```

因此汇总可以：

> **隐藏内部细节变化，降低路由震荡向其他区域传播的影响。**

但注意：

**如果所有明细路由都消失，汇总本身也可能消失。**

---

# 13. 汇总路由 Cost

这里要特别注意：

不同厂商、不同版本的实现可能存在差异。

实验时建议：

```cisco
show ip ospf database
show ip route
```

结合修改明细路由 cost 的方式进行验证。

Cisco 与 Huawei 关于汇总 cost 的具体实现不要死记未经验证的资料，考试时应以对应版本的官方文档/考试蓝图为准。

---

# 二、ASBR 路由汇总

# 1. 什么是 ASBR？

ASBR：

> **Autonomous System Boundary Router**

即：

> **自治系统边界路由器**

它负责：

```text
OSPF
  ↕
其他路由来源
```

例如：

```text
Static
Connected
EIGRP
BGP
其他协议
      ↓
    ASBR
      ↓
    OSPF
```

---

# 2. ABR 与 ASBR 的区别

这是 CCNP 很重要的区别：

||ABR|ASBR|
|---|---|---|
|全称|Area Border Router|Autonomous System Boundary Router|
|作用|连接不同 OSPF Area|连接 OSPF 与外部路由|
|典型路由|Area 内部/区域间路由|外部路由|
|汇总命令|`area X range`|`summary-address`|
|典型 LSA|Type 3 等|Type 5|

记忆：

> **ABR 管 Area ↔ Area**  
> **ASBR 管 OSPF ↔ External**

---

# 3. ASBR 外部路由实验

例如 R3 上存在：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
```

不再直接通过：

```text
ip ospf 110 area 1
```

宣告，而是作为外部路由引入 OSPF：

```cisco
router ospf 110
 redistribute connected
```

此时 R3 可以成为：

```text
ASBR
```

---

# 4. OSPF 外部路由默认 Metric

OSPF 引入外部路由时，Cisco 默认外部 metric 通常为：

```text
20
```

例如：

```cisco
redistribute connected
```

引入的外部路由可能表现为：

```text
O E2
```

默认情况下：

```text
Metric = 20
```

考试中要特别注意：

> **E1 与 E2 的路径计算方式不同。**

---

# 5. ASBR 汇总命令

在 ASBR 上：

```cisco
router ospf 110
 summary-address 192.168.0.0 255.255.248.0
```

作用：

```text
192.168.0.1/32
192.168.1.1/32
192.168.2.1/32
192.168.3.1/32
192.168.4.1/32
        ↓
192.168.0.0/21
```

---

# 6. ASBR 汇总后的 LSA 类型

ASBR 引入外部路由后：

```text
Type 5 LSA
```

因此：

```text
ASBR
 ↓
External Route
 ↓
Type 5 LSA
```

汇总后的外部路由仍然属于：

> **OSPF External Route**

---

# 7. ABR 汇总 vs ASBR 汇总

必须重点记住：

```text
ABR
 ↓
Area 内部路由
 ↓
area X range
 ↓
Type 3 Summary LSA
```

而：

```text
ASBR
 ↓
外部路由
 ↓
summary-address
 ↓
Type 5 External LSA
```

一句话：

> **Area 内部路由汇总 → ABR → `area range`**  
> **外部路由汇总 → ASBR → `summary-address`**

---

# 三、ASBR 汇总 + not-advertise

## 1. 配置

```cisco
router ospf 110
 summary-address 192.168.0.0 255.255.248.0 not-advertise
```

---

## 2. `not-advertise` 的本质

它不仅仅是：

> “汇总”

而是：

> **抑制这些外部路由的通告。**

普通汇总：

```text
明细路由
   ↓
抑制明细
   ↓
发布汇总
```

`not-advertise`：

```text
明细路由
   ↓
抑制明细
   ↓
同时不发布汇总
```

所以邻居最终：

```text
看不到明细
也看不到汇总
```

可以把它理解成：

> **一种特殊的路由过滤手段。**

---



# 九、实验验证命令汇总

## OSPF 邻居

```cisco
show ip ospf neighbor
```

## OSPF 接口

```cisco
show ip ospf interface
```

## OSPF LSDB

```cisco
show ip ospf database
```

## 路由表

```cisco
show ip route
```

## OSPF 邻居调试

```cisco
debug ip ospf adj
```

## 关闭 Debug

```cisco
undebug all
```

---

# 十、考试最容易混淆的知识点

## ① ABR 和 ASBR

```text
ABR：
连接不同 Area

ASBR：
连接 OSPF 与外部路由
```

---

## ② ABR 汇总和 ASBR 汇总

```text
ABR
 ↓
区域内部路由
 ↓
area X range
```

```text
ASBR
 ↓
外部路由
 ↓
summary-address
```

---

## ③ `not-advertise`

普通：

```text
summary-address
```

结果：

```text
明细不传播
汇总传播
```

加入：

```text
not-advertise
```

结果：

```text
明细不传播
汇总也不传播
```

因此：

> **`not-advertise` 本质上具有路由过滤效果。**

---

## ④ Type 3 和 Type 5

```text
Type 3
↓
Summary LSA
↓
ABR
↓
区域间路由
```

```text
Type 5
↓
AS External LSA
↓
ASBR
↓
外部路由
```

---

## ⑤ 明文认证和 MD5

```text
Simple Password
= Type 1
= 密码明文

Cryptographic
= Type 2
= 摘要认证
```

---

# 十一、最终思维导图

```text
                    OSPF
                     │
          ┌──────────┴──────────┐
          │                     │
       路由汇总                认证
          │                     │
    ┌─────┴─────┐        ┌──────┴──────┐
    │           │        │             │
   ABR         ASBR     接口认证       区域认证
    │           │        │             │
Area内部       外部路由   Interface     Area
    │           │
area X range   summary-address
    │           │
Type 3         Type 5
```

