- 基本概念：EIGRP支持两种负载均衡方式，等价负载均衡是IGP协议通用机制，而非等价负载均衡是EIGRP特有功能。
- 默认配置：默认情况下EIGRP会在4条度量值完全相同的路径之间进行流量分配。
- 上限调整：通过maximum-paths命令可修改最大路径数，真机设备最大支持16条


如图

![[Pasted image 20260923144915.png]]

R1到达R4的loopback0有两条路径，由于有两条路都可以抵达所以两个路由器R2和R3都是R1的后继路由器
![[Pasted image 20260923145126.png]]

而我们修改最大路径数量
```

R1(config)#router eigrp 90
R1(config-router)#maximum-paths 1

```

![[Pasted image 20260923150003.png]]
这个时候只有一条路径了。
