#### QinQ只能在入接口配置！！！！

拓扑图
![[Pasted image 20260904102048.png]]
更清楚地画：


R1：

```
interface Ethernet0/1
 no shutdown

interface Ethernet0/1.8
 encapsulation dot1Q 8
 ip address 192.168.1.1 255.255.255.0
```

R2：

```
interface Ethernet0/1
 no shutdown

interface Ethernet0/1.8
 encapsulation dot1Q 8
 ip address 192.168.1.2 255.255.255.0
```

这里：

```
encapsulation dot1Q 8
```

表示：

> R1/R2 使用 **VLAN 8**。

所以 R1 发出的帧可以理解成：

```
[C-VLAN 8]
```

S1:

```
interface GigabitEthernet0/0
 switchport access vlan 100
 switchport mode dot1q-tunnel
 
 
 interface GigabitEthernet0/1
 switchport trunk encapsulation dot1q 
 switchport mode trunk 
 switchport trunk allowed vlan 100
 
```

S2:
```
interface GigabitEthernet0/0
 switchport trunk allowed vlan 100
 switchport trunk encapsulation dot1q
 switchport mode trunk
 
 
 interface GigabitEthernet0/1
 switchport trunk allowed vlan 100
 switchport trunk encapsulation dot1q
 switchport mode trunk
```

S3:

```
interface GigabitEthernet0/1
 switchport access vlan 100
 switchport mode dot1q-tunnel
 
 
 interface GigabitEthernet0/0
 switchport trunk encapsulation dot1q 
 switchport mode trunk 
 switchport trunk allowed vlan 100
 
```


成功了
![[Pasted image 20260904105300.png]]

![[Pasted image 20260920183039.png]]
其中会有两个Virtual Lan.一个100,一个8



