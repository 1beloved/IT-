# Linux 服务器自动巡检脚本

用 Bash 编写的服务器巡检脚本。一次运行即可检查主机状态、资源使用、关键服务和网络连通性，生成带"正常/异常"标记的巡检报告，并统计异常项数量。

## 检查内容

| 类别 | 检查项 |
|---|---|
| 系统 | 主机名、系统运行时间 |
| 资源 | 系统负载（对比 CPU 核心数）、CPU 使用率、内存使用率、各挂载点磁盘使用率（/、/boot） |
| 服务 | sshd 服务运行状态 |
| 网络 | 默认路由、SSH 22 端口监听、DNS 解析（example.com） |
| 日志 | 系统错误级别日志 |

## 运行环境

- 系统：CentOS Stream 10（虚拟机）
- 语言：Bash

## 使用方法

~~~bash
git clone https://github.com/1beloved/IT-.git
cd IT-/linux/server-inspection
chmod +x inspect.sh
./inspect.sh
~~~

运行后，巡检报告生成在 `reports/` 目录，文件名带时间戳；运行记录写入 `logs/inspection.log`（目录路径以脚本中的设置为准）。

## 输出示例

完整报告见 [sample-report.txt](sample-report.txt)，节选如下：

~~~text
[正常] 系统负载：1分钟负载为 0.13，CPU逻辑核心数为 4
[正常] 内存使用率：31%
[正常] 磁盘 /：使用率 25%
[正常] SSH服务：sshd 正在运行
[正常] DNS解析：example.com 解析成功
正常项：10，异常项：0
~~~

## 说明

- 报告中的 IP 为虚拟机内网地址，仅用于实验环境。
- 个人学习项目，欢迎指正。
