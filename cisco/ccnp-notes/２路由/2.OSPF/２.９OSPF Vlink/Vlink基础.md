# OSPF Virtual Link（VLink）虚链路 —— CCNP考点总结

---

# 一、为什么需要VLink？

## 1. OSPF区域设计规则

OSPF要求：

```
              Area 0
                 |
       -------------------
       |        |        |
    Area1    Area2    Area3
```

原则：

1. 必须存在且只有一个Area 0
    
2. 所有非骨干区域必须连接Area 0
    
3. 非骨干区域之间不能直接连接
    

原因：

> OSPF区域间依靠Area 0传递三类LSA，Area 0是整个OSPF域的骨干。

你的笔记中强调：

- 骨干区域唯一性
    
- 非骨干区域必须连接Area 0
    
- VLink只是临时解决方案  
    

---

# 二、错误拓扑为什么需要VLink？

## 场景1：Area 0断开

例如：

```
Area0       Area1       Area0

 R1 -------- R2 -------- R3
```

问题：

实际上：

```
Area0 ---- Area1 ---- Area0
```

两个Area 0不是连续的。

结果：

- OSPF认为存在两个骨干区域
    
- 区域间路由异常
    

---

## 场景2：非骨干区域连接非骨干区域

错误：

```
Area0

 |
Area1

 |
Area2
```

问题：

Area1和Area2之间没有Area0。

中间设备：

```
R2

Area1
 |
Area2
```

虽然属于两个区域：

但是：

❌ 不是ABR

原因：

ABR必须：

1. 属于多个区域
    
2. 至少一个接口属于Area0
    

---

# 三、什么是VLink？

定义：

> Virtual Link是一条通过非骨干区域建立的逻辑OSPF链路，它在逻辑上属于Area 0。

重点：

三个关键词：

```
逻辑链路
属于Area0
通过Transit Area建立
```

你的笔记：

> 不要求物理连续，只要求逻辑连续；永远属于区域0。  

---

# 四、VLink基本结构

例如：

```
             Area0

        R1 -------- R3


             |
          Area1
             |

        R1 -------- R2

```

R1：

连接：

```
Area0
Area1
```

R2：

连接：

```
Area1
```

现在：

R2想连接Area0。

建立：

```
R1 ================= R2

       Virtual Link
```

逻辑：

```
Area0 -------- Area0
```

---

# 五、VLink中的重要角色

## 1. Transit Area

穿越区域。

要求：

必须是：

```
普通Area
```

不能：

- Stub Area
    
- Totally Stub
    
- NSSA
    

原因：

VLink需要传递LSA。

---

## 2. 两端必须是ABR

VLink连接：

```
ABR -------- ABR
```

不是：

```
普通Router -------- ABR
```

---

# 六、VLink配置（CCNP重点）

命令：

```cisco
router ospf 1

area transit-area-id virtual-link remote-router-id
```

例如：

拓扑：

```
R1 RID 1.1.1.1

R2 RID 2.2.2.2


Transit Area 1
```

R1:

```cisco
router ospf 1

area 1 virtual-link 2.2.2.2
```

R2:

```cisco
router ospf 1

area 1 virtual-link 1.1.1.1
```

---

# 七、VLink认证（重点补充）

VLink本质：

也是OSPF邻居关系。

所以：

> VLink可以使用OSPF Authentication。

---

# 1. VLink明文认证

配置：

```cisco
router ospf 1

area 1 virtual-link 2.2.2.2 authentication-key Cisco
```

含义：

```
Transit Area:
Area 1


Remote ABR:
2.2.2.2


Password:
Cisco
```

---

# 2. VLink MD5认证（考试重点）

配置：

```cisco
router ospf 1

area 1 virtual-link 2.2.2.2 authentication message-digest


area 1 virtual-link 2.2.2.2 message-digest-key 1 md5 Cisco
```

解释：

第一条：

开启MD5：

```
authentication message-digest
```

第二条：

配置：

```
Key ID
Password
```

类似接口MD5：

```cisco
ip ospf message-digest-key
```

---

# 八、VLink认证注意事项

## 1. 两端认证必须一致

例如：

R1:

```
MD5

Key ID 1

Password Cisco
```

R2:

```
MD5

Key ID 1

Password Cisco
```

成功。

---

如果：

```
R1:
Password Cisco


R2:
Password cisco
```

失败。

---

# 九、查看VLink状态

## 1. 查看OSPF虚链路

命令：

```cisco
show ip ospf virtual-links
```

正常：

```
Virtual Link OSPF_VL0 to router 2.2.2.2 is up
```

---

## 2. 查看邻居

```cisco
show ip ospf neighbor
```

会看到：

```
FULL
```

---

## 3. 查看接口

```cisco
show ip ospf interface virtual-link 2.2.2.2
```

---

# 十、VLink常见故障排查

## 问题1：

Virtual Link DOWN

检查：

---

### ① RID是否正确

错误：

```cisco
area 1 virtual-link 2.2.2.3
```

实际：

```
RID=2.2.2.2
```

失败。

---

### ② Transit Area是否正确

两端：

必须：

```
area 1 virtual-link x.x.x.x
```

不能：

R1：

```
area1
```

R2：

```
area2
```

---

### ③ Transit Area不能是特殊区域

不能：

```
Stub
Totally Stub
NSSA
```

---

### ④ Authentication是否匹配

检查：

- 类型
    
- Key
    
- Password
    

---

# 十一、VLink和普通OSPF认证区别

||普通接口认证|VLink认证|
|---|---|---|
|位置|interface|router ospf|
|对象|物理接口邻居|逻辑虚链路|
|作用|认证OSPF邻居|认证Virtual Link|
|MD5|支持|支持|
|密码|接口配置|virtual-link配置|

---

# 十二、CCNP高频陷阱总结

## 题目1：

> Virtual Link属于哪个区域？

答案：

✅ Area 0

不是：

❌ Transit Area

---

## 题目2：

> Virtual Link是否需要物理直连Area0？

答案：

❌ 不需要

要求：

逻辑连接。

---

## 题目3：

> Virtual Link经过什么区域？

答案：

Transit Area

---

## 题目4：

> Stub Area可以建立Virtual Link吗？

答案：

❌ 不可以

---

## 题目5：

> Virtual Link两端是什么设备？

答案：

ABR

---

## 题目6：

> Virtual Link认证在哪里配置？

答案：

OSPF进程模式：

```cisco
area X virtual-link RID authentication...
```

不是：

interface。

---

# 十三、OSPF VLink最终背诵版

```
VLink:

目的:
解决Area0不连续问题

本质:
逻辑Area0链路


特点:
- 属于Area0
- 经过Transit Area
- 两端必须ABR
- Transit Area不能是Stub/NSSA


配置:

router ospf 1

area transit-area virtual-link RID


认证:

明文:
area X virtual-link RID authentication-key password


MD5:

area X virtual-link RID authentication message-digest

area X virtual-link RID message-digest-key ID md5 password


检查:

show ip ospf virtual-links

```

对于 CCNP ENCOR，这一块和 **ABR、LSA Type 3、OSPF区域设计、防环机制**经常一起考。你现在已经学完 OSPF 多区域、特殊区域、认证，下一步建议把 **OSPF LSA 1-7 + ABR/ASBR角色 + VLink综合拓扑题**串起来，这会接近考试综合题难度。