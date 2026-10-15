
此时有两个area 0和area 1在中间，两边都有Area 0，R2和R3都是ABR并且接入了area 0的接口，那么R2中不会有R3的那边的Area 0区域的路由，因为Area 0不会接受从Abr传来的Area 0路由信息。这是为了防环

![[Pasted image 2026091812021.png]]


查看数据表与路由表区别
在R2的database中可以看到30.1.1.0的区域信息，但是它却不会传入到R1中，只接受不学习
![[Pasted image 20260918114942.png]]

此时发现有R3传来的30.1.1.0信息

![[Pasted image 20260918115019.png]]

但是在show ip route中却没有30.1.1.0的路由信息。

接下来配置路由，需要在**R2与R3之间配置虚拟链路，并且配置对方的router-id**
```
R2(config-router)#area 1 virtual-link 3.3.3.3

R3(config-router)#area 1 virtual-link 2.2.2.2

```
配置完后抓包发现
![[Pasted image 20260918120219.png]]
此时20.1.1.2端口同时发送两种报文，一种是向224.0.0.5发送的组播报文，一种是向对端3.3.3.3发送的单播报文，而信息呢是area 0的信息，在R3配置完后双方虚拟链路配置成功


如果是area 0 -----> area 1 -----> area 2也是同样的配置和原理
![[Pasted image 20260918123730.png]]
拓扑结构就会变成
![[Pasted image 20260918123839.png]]

如果是area 1 -----> area 2 -----> area 3也是同样的配置
![[Pasted image 20260918124006.png]]那么它同样可以用这条虚拟的链路进行连接
show ip ospf database查看数据库信息
![[Pasted image 20260918124645.png]]

可以看到area 0依旧存在，除非R2 ---- R3的链路断开。
这个DNA标识Do not age永远不老化，虚拟链路时间是不老化的。