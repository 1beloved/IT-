EIGRP跟OSPF认证差不多，只是EIGRP不支持明文加密。

传统的EIGRP只支持MD5，而命名模式下的EIGRP支持MD5和其它

R1(config-if)#ip authentication mode eigrp AS md5

R1(config-if)#ip authentication key-chain eigrp AS Key-chainName
### ① 创建 Key Chain

```
R1(config)# key chain EIGRP-AUTH
R1(config-keychain)# key 1
R1(config-keychain-key)# key-string cisco123
R1(config-keychain-key)# exit
R1(config-keychain)# exit
```

此时：

```
Key Chain
└── EIGRP-AUTH
     └── Key 1
          └── cisco123
```

---

### ② 在接口启用 MD5

```
R1(config)# interface g0/0
R1(config-if)# ip authentication mode eigrp 100 md5
```

这个命令：

```
ip authentication mode eigrp 100 md5
```

表示：

> AS 100 的 EIGRP 使用 MD5 认证。

---

### ③ 指定 Key Chain

```
R1(config-if)# ip authentication key-chain eigrp 100 EIGRP-AUTH
```

于是完整配置：

```
R1(config)# key chain EIGRP-AUTH
R1(config-keychain)# key 1
R1(config-keychain-key)# key-string cisco123
R1(config-keychain-key)# exit
R1(config-keychain)# exit

R1(config)# interface g0/0
R1(config-if)# ip authentication mode eigrp 100 md5
R1(config-if)# ip authentication key-chain eigrp 100 EIGRP-AUTH
```


实验图如下。
先在R1上创建密钥链。

```
key chain CCNP
 key 1
  key-string KFC
 key 2
  key-string MC
```

然后到接口下开启认证然后把CCNP添加进认证规则
```

R1(config-if)#ip authentication mode eigrp 90 md5

R1(config-if)#ip authentication key-chain eigrp 90 CCNP


```