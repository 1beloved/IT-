
> **Stub 是“不让外面的 Type 5 进来”；NSSA 是“不让外面的 Type 5 进来，但允许我自己在区域里产生外部路由”。**

---

# 1. 先把四种特殊区域放到一张表

这是你现在最值得背的一张表：

| 区域                 | Type 3 | Type 4 | Type 5 | Type 7 | 默认路由   |
| ------------------ | ------ | ------ | ------ | ------ | ------ |
| 普通区域               | ✅      | ✅      | ✅      | ❌      | 不一定    |
| **Stub**           | ✅      | ❌      | ❌      | ❌      | Type 3 |
| **Totally Stubby** | ❌*     | ❌      | ❌      | ❌      | Type 3 |
| **NSSA**           | ✅      | ❌      | ❌      | ✅      | 视实现/配置 |
| **Totally NSSA**   | ❌*     | ❌      | ❌      | ✅      | Type 3 |

* 表示**普通的 Type 3 被阻止**，但 ABR 发出的默认路由仍然是 Type 3。

这一张表基本可以解决大量选择题。

---

# 2. NSSA到底解决什么问题？

先回忆 Stub。

Stub 的规则：

```text
其他区域
   ↓
Type 5 ❌
Type 4 ❌
```

好处是减少外部 LSA。

但是 Stub 有一个问题：

> **区域内部不能有 ASBR，不能把自己的外部路由注入 OSPF。**

例如：

```text
                Area 0
             R2 -------- R3
                         |
                       Area 2
                         |
                        R4
                         |
                       Internet
```

如果 R4 连接互联网，并且 R4 上存在：

```text
200.1.1.0/24
```

你想：

```text
R4
 ↓
redistribute
 ↓
OSPF
```

普通 Stub 不允许这么干。

因为 Stub 不允许 Type 5。

---

# 3. NSSA就是为了解决这个问题

NSSA：

```text
其他区域的 Type 5
        ↓
       ❌

本区域自己的外部路由
        ↓
      Type 7
        ↓
       ✅
```

所以：

```text
Stub：

外部路由 ❌


NSSA：

别人的外部路由 ❌
自己的外部路由 ✅
```

你笔记里的这个口诀其实非常好：

> **“NSSA很双标：别人的外部路由我不要，自己的外部路由必须搞。”**

这个可以继续保留。

---

# 4. 为什么需要 Type 7？

因为 NSSA 本身不允许 Type 5。

所以 R4 不能：

```text
R4
 ↓
Type 5
```

而是：

```text
R4
 ↓
Type 7
```

例如：

```text
4.4.4.4/32
5.5.5.5/32
6.6.6.6/32
```

R4 redistribute：

```cisco
redistribute connected subnets
```

之后：

```text
R4（NSSA ASBR）
       |
       | Type 7
       ↓
      R3
       |
       | 转换
       ↓
     Type 5
       |
       ↓
   Area 0 / Area 1
```

所以 Type 7 的核心作用就是：

> **让 NSSA 区域内部能够携带外部路由。**

---

# 5. “7类LSA是5类LSA的马甲”这个理解很好

你可以把它想象成：

```text
        NSSA内部
           
外部路由
   ↓
Type 7
   ↓
ABR
   ↓
Type 5
   ↓
其他区域
```

因此：

> **Type 7 不是整个 OSPF 域通用的外部 LSA。**

它主要是：

> **NSSA区域内部使用的外部路由描述方式。**

出了 NSSA 后，就转换成标准 Type 5。

---

# 6. 谁产生 Type 7？

这个必须记清楚：

> **NSSA 内部的 ASBR 产生 Type 7。**

例如：

```text
               Area 0
                  |
                 R3
                ABR
                  |
               Area 2
                  |
                 R4
               ASBR
                  |
              外部网络
```

R4：

```text
redistribute connected
```

R4 就产生：

```text
Type 7
```

R3 是 ABR。

R3负责：

```text
Type 7 → Type 5
```

所以这里有两个角色：

```text
R4：
ASBR
产生 Type 7


R3：
ABR
负责 Type 7 → Type 5
```

而 R3 在把 Type 7 转成 Type 5、向其他区域传播后，也承担 ASBR 相关角色。

---

# 7. Type 4为什么NSSA里面没有？

你笔记写：

> “不需要4类LSA”

这个方向是对的。

原因和 Stub 一样。

Type 4 的作用是：

> **帮助其他区域找到 ASBR。**

但是 NSSA 中的 Type 7 有自己的机制来描述外部路由以及相关信息。

因此 NSSA 不允许其他区域的 Type 4 进入。

所以：

```text
NSSA：

Type 4 ❌
Type 5 ❌
Type 7 ✅
```

---

# 8. NSSA和Stub最重要的区别

你可以用一个现实场景理解。

### Stub

```text
             Internet
                |
              Area 0
                |
               ABR
                |
             Stub Area
                |
               PC
```

Stub区域只是一个：

> **纯粹的末梢区域。**

它自己不需要引入外部路由。

---

### NSSA

```text
             Area 0
                |
               ABR
                |
             NSSA
                |
          R4（ASBR）
             /   \
        Internet  外部网络
```

这个区域：

> **既是末梢区域，又需要自己引入外部路由。**

所以：

```text
Stub → 不允许ASBR
NSSA → 可以有ASBR
```

这就是为什么 NSSA 叫：

> **Not-So-Stubby Area**

不是那么“纯”的 Stub。

---

# 9. 你笔记中一个需要特别注意的地方：NSSA默认路由

你写：

> “ABR会产生一条7类NSSA的默认路由(0.0.0.0)”

这个**不能作为 Cisco CCNP 的通用结论直接背**。

更稳妥的理解是：

### 普通 NSSA

NSSA 本身并不等于：

> ABR一定自动给你一条 Type 7 默认路由。

默认路由行为和具体厂商/配置有关。

Cisco 中常见的是通过：

```cisco
area 2 nssa
```

配置 NSSA；如果需要让 ABR 注入默认路由，相关行为需要看具体 IOS/配置方式。

而：

### Totally NSSA

```cisco
area 2 nssa no-summary
```

ABR 会向 NSSA 区域提供默认路由，用来代替大量区域间明细路由。

所以考试时：

> **不要简单背“NSSA一定自动产生7类默认路由”。**

---

# 10. Totally NSSA就更好理解了

我们已经有：

```text
NSSA：

1
2
3
7
```

但是它还有很多 Type 3：

```text
O IA 10.1.1.0/24
O IA 20.1.1.0/24
O IA 30.1.1.0/24
...
```

如果这是一个真正的末梢区域：

> 这些明细路由其实也没必要全部知道。

所以：

```text
NSSA
 ↓
no-summary
 ↓
Totally NSSA
```

例如：

```cisco
router ospf 110
 area 2 nssa no-summary
```

于是：

```text
Type 3普通明细 ❌
Type 4 ❌
Type 5 ❌
Type 7 ✅
默认路由 ✅
```

---

# 11. 这就是四种区域的“进化路线”

你现在可以把它理解成：

```text
普通区域
│
├── Stub
│    │
│    └── Totally Stubby
│
└── NSSA
     │
     └── Totally NSSA
```

为什么越来越“特殊”？

因为每一步都是在：

> **减少不必要的LSA，同时保留这个区域真正需要的功能。**

---

# 12. 最后给你一张真正适合考试的速记表

### Stub

```text
1 ✅
2 ✅
3 ✅
4 ❌
5 ❌
7 ❌

可以引入外部路由：❌
默认路由：ABR提供
```

### Totally Stubby

```text
1 ✅
2 ✅
普通3 ❌
4 ❌
5 ❌
7 ❌

默认路由：ABR提供
```

### NSSA

```text
1 ✅
2 ✅
3 ✅
4 ❌
5 ❌
7 ✅

可以引入外部路由：✅
外部路由 → Type 7
ABR：Type 7 → Type 5
```

### Totally NSSA

```text
1 ✅
2 ✅
普通3 ❌
4 ❌
5 ❌
7 ✅

可以引入外部路由：✅
默认路由：ABR提供
```

---

## ⭐ 你现在只需要牢牢记住这一句话

> **Stub：我不要外面的5类。**  
> **Totally Stubby：我连外面的3类明细也不要。**  
> **NSSA：我不要外面的5类，但我要允许自己产生7类。**  
> **Totally NSSA：我连外面的3类明细也不要，但我仍然可以产生7类。**

然后再补一个非常重要的考试点：

> **Type 7 只存在于 NSSA 内；ABR 可以把 Type 7 转换成 Type 5，让外部路由进入其他普通区域。**

你现在把 **Stub / Totally Stubby / NSSA / Totally NSSA** 这四个搞明白之后，OSPF特殊区域这一大块基本就串起来了。