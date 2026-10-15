
# OSPF Authentication（OSPF认证）

## 一、为什么需要OSPF认证？（考点）

OSPF通过 Hello 报文发现邻居。

默认情况下：

```
任何运行OSPF的设备
        ↓
发送Hello
        ↓
可能尝试建立邻居
        ↓
影响路由表
```

风险：

- 非授权设备加入OSPF
    
- 恶意发送LSA
    
- 路由信息被篡改
    

所以：

> **OSPF Authentication 用于验证OSPF邻居身份，并保证OSPF报文完整性。**

注意：

OSPF认证：

✅ 防止非法邻居  
✅ 防止报文篡改

但是：

❌ 不负责加密OSPF流量

---

# 二、OSPF认证类型（必考）

OSPF Header中有 Authentication Type 字段。

|Auth Type|名称|特点|
|---|---|---|
|0|Null Authentication|无认证|
|1|Simple Password|明文密码|
|2|Cryptographic Authentication|摘要认证（MD5/HMAC）|

记忆：

```
0 = Nothing
1 = Clear text
2 = Crypto
```

---

# 三、Null Authentication（Type 0）

默认：

```text
OSPF不认证
```

抓包：

```
Auth Type = 0
```

没有密码。

---

# 四、Simple Password Authentication（Type 1）

也叫：

- Plain Text Authentication
    
- Simple Password
    

## 1. 配置

接口：

```cisco
interface g0/0

ip ospf authentication

ip ospf authentication-key Cisco123
```

作用：

第一条：

```
开启OSPF认证
```

第二条：

```
配置明文密码
```

注意顺序：

只有：

```
authentication-key
```

没有：

```
authentication
```

不会生效。

---

## 2. 抓包特点

OSPF Header:

```
Authentication Type = 1
```

可以看到：

```
Password
```

安全性：

低。

原因：

密码直接携带在OSPF报文中。

---

# 五、MD5 Authentication（Type 2）

考试重点。

## 1. 配置

接口：

```cisco
interface g0/0

ip ospf message-digest-key 1 md5 Cisco123

ip ospf authentication message-digest
```

第一条：

配置：

```
Key ID
密码
```

第二条：

开启：

```
MD5认证
```

---

# 六、MD5工作原理（重点理解）

MD5不是加密。

流程：

例如：

R1发送OSPF Hello：

```
OSPF Packet
+
Password
+
Key ID

        ↓

MD5 Hash计算

        ↓

生成Digest

        ↓

发送
```

R2：

收到：

```
OSPF Packet
+
Digest
```

然后：

自己计算Hash。

比较：

一致：

```
认证成功
```

不一致：

```
丢弃报文
```

---

## 注意：

MD5不会隐藏：

- OSPF报文内容
    

不会：

```
加密LSA
```

只是：

```
认证 + 完整性校验
```

---

# 七、OSPF Authentication配置方式

Cisco有两种：

---

# 方式1：接口认证（Interface Authentication）

配置：

```
interface
```

例如：

```cisco
interface g0/0

ip ospf authentication message-digest

ip ospf message-digest-key 1 md5 Cisco
```

特点：

影响：

```
当前接口
```

优点：

精细控制。

适合：

不同链路不同密码。

---

# 方式2：区域认证（Area Authentication）

配置：

```
router ospf
```

例如：

明文：

```cisco
router ospf 1

area 0 authentication
```

MD5：

```cisco
router ospf 1

area 0 authentication message-digest
```

作用：

告诉该Area：

```
所有接口需要认证
```

但是：

注意：

区域认证只是：

> 开启认证类型

不是：

> 自动生成密码

MD5仍然需要：

```cisco
ip ospf message-digest-key
```

---

# 八、区域认证 vs 接口认证（考试比较）

|项目|Interface|Area|
|---|---|---|
|位置|接口|OSPF进程|
|范围|一个接口|整个Area|
|灵活性|高|低|
|适合|特殊链路|统一部署|
|密码配置|接口|仍需接口/key-chain|

---

# 九、认证匹配规则（CCNP常考）

两个邻居：

必须匹配：

## 1. Authentication Type

例如：

R1:

```
MD5
```

R2:

```
Simple Password
```

结果：

```
邻居失败
```

---

## 2. Password

大小写敏感。

例如：

```
Cisco

≠

cisco
```

---

## 3. Key ID（MD5）

例如：

R1:

```
Key ID 1
Password ABC
```

R2:

```
Key ID 2
Password ABC
```

可能失败。

因为：

Key ID也是认证信息的一部分。

---

# 十、OSPF Key Chain（CCNP补充重点）

传统MD5：

```cisco
ip ospf message-digest-key
```

缺点：

密码长期固定。

生产环境：

需要：

> 密钥轮换（Key Rotation）

所以Cisco支持：

## Key Chain

---

# 1. Key Chain结构

关系：

```
Key Chain

   |
   |
 Key 1
   |
 Password


 Key 2
   |
 Password
```

---

# 2. 配置示例

创建Key Chain：

```cisco
key chain OSPF_KEYS
```

进入key：

```cisco
key 1

key-string Cisco123
```

第二个：

```cisco
key 2

key-string Cisco456
```

---

接口调用：

```cisco
interface g0/0

ip ospf authentication key-chain OSPF_KEYS
```

---

# 3. Key Chain作用

主要：

## 密钥自动切换

例如：

```
Key 1

有效时间：
00:00-12:00


Key 2

有效时间：
12:00-24:00
```

设备自动选择当前有效Key。

---

# 十一、Key Chain时间控制（了解）

Key可以配置：

开始时间：

```
accept-lifetime
```

发送时间：

```
send-lifetime
```

例如：

```cisco
key 1

accept-lifetime 00:00:00 Jan 1 2026 infinite

send-lifetime 00:00:00 Jan 1 2026 infinite
```

生产中用于：

不停机更换密码。

---

# 十二、OSPF认证查看命令（必考）

## 查看接口认证

```cisco
show ip ospf interface g0/0
```

看到：

```
Message digest authentication enabled
```

---

## 查看邻居

```cisco
show ip ospf neighbor
```

---

## 查看OSPF进程

```cisco
show ip ospf
```

---

## Debug

```cisco
debug ip ospf adj
```

典型错误：

```
Mismatch Authentication type
```

或者：

```
Invalid authentication
```

---

# 十三、认证失败现象

配置错误：

```
R1 -------- R2

Hello发送

↓

认证失败

↓

Hello被丢弃

↓

Dead Timer超时

↓

Neighbor Down
```

常见现象：

```
Neighbor stuck in INIT
```

或者：

```
DOWN
```

---

# 十四、CCNP考试高频陷阱总结

## 1.

问题：

> 配置ip ospf message-digest-key后是否立即启用MD5？

答案：

❌ 不一定。

还需要：

```cisco
ip ospf authentication message-digest
```

---

## 2.

问题：

> MD5是否加密OSPF？

答案：

❌

它：

```
验证身份
+
检测完整性
```

不是：

```
Encryption
```

---

## 3.

问题：

> Area authentication是否自动配置密码？

答案：

❌

只是：

```
启用认证方式
```

---

## 4.

问题：

> DR和认证有什么关系？

答案：

没有直接关系。

DR：

```
优化LSA泛洪
```

Authentication：

```
验证邻居
```

---

## 5.

问题：

> Key Chain主要目的？

答案：

```
自动密钥轮换
```

---

# 最终CCNP速记版

```
OSPF Authentication

Type 0:
Null
无认证


Type 1:
Simple Password
明文


Type 2:
Cryptographic
MD5/HMAC


Simple:
authentication-key
+
authentication


MD5:
message-digest-key
+
authentication message-digest


Area:
控制认证类型


Interface:
配置具体密码


Key Chain:
生产环境密钥轮换


MD5 ≠ Encryption

认证失败:
Hello丢弃
Neighbor Down
```

这部分在 **CCNP ENCOR 350-401** 中属于 **Network Assurance / Infrastructure Security相关考点**，难度不高，但是非常容易和 **OSPF邻居状态、DR/BDR、LSA同步**混在一起考。你现在学到这里，建议下一步把 **OSPF邻居建立全过程（Down→Full）+ Authentication在哪一步生效** 结合起来，这个非常容易出综合题。