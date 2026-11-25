# 配置与被禁标志

🌐 [Italiano](../04-profili.md) · [English](../en/04-profili.md) · **中文**

> ⚠️ 本页为机器翻译草稿，正式发布前需母语者校对。

| 配置 | 作用 | 噪声 | Root |
|---|---|---|---|
| `triage` | 小字典，用于了解目标如何响应。 | 中 | 否 |
| `cartelle` | 目录发现，带自动校准。 | 高 | 否 |
| `ricorsivo` | 与 cartelle 相同，并进入找到的目录。 | 高 | 否 |
| `file` | 带常见扩展名的文件。 | 高 | 否 |
| `backup` | 备份文件和编辑器残留文件。 | 高 | 否 |
| `api` | API 端点。 | 高 | 否 |
| `parametri` | 参数名。 | 高 | 否 |
| `prudente` | 目录发现，10 个线程、每秒 2 个请求。 | 中 | 否 |

`ffuf-cli profili` 会打印每个配置的具体标志。

## 各配置的作用

**triage** (`无额外标志`). 小字典，用于了解目标如何响应。 在任何长时间扫描之前：先看看服务器返回哪种类型的响应。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/common.txt`。

**cartelle** (`-ac`). 目录发现，带自动校准。 主要工作：现代应用的典型目录结构。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`。

**ricorsivo** (`-ac -recursion -recursion-depth 2`). 与 cartelle 相同，并进入找到的目录。 在找到 /admin 后，继续在 /admin 内部查找。深度限制为 2：否则队列会急剧膨胀。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`。

**file** (`-e .php,.bak,.old,.txt,.zip`). 带常见扩展名的文件。 用于查找被遗忘的脚本和归档文件。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`。

**backup** (`-e .bak,.old,.backup,.copy,.orig,.save,.swp,.tmp -mc 200`). 备份文件和编辑器残留文件。 查找遗留在服务器上的代码副本：它们常常包含凭据。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`。

**api** (`-mc 200,201,401,403,405`). API 端点。 对一个存在的接口返回 401 或 403，和返回 200 一样是有用的结果。 URL：`{origine}/api/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/api-endpoints.txt`。

**parametri** (`-fs 0`). 参数名。 用于发现某个接口未公开的参数。 URL：`{origine}/api?FUZZ=test`，默认字典：`/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt`。

**prudente** (`-ac -t 10 -rate 2`). 目录发现，10 个线程、每秒 2 个请求。 在客户基础设施上默认使用的配置。 URL：`{origine}/FUZZ`，默认字典：`/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`。

## 手动传入标志

`--` 之后写的所有内容都会追加在配置标志之后传给 ffuf，前提是不在被禁清单中。比对时不区分大小写，`-flag valore` 和 `-flag=valore` 两种写法都能识别，一个或两个短横线均可。

```sh
ffuf-cli lancia prudente https://app.example.org --scope scope.toml -- -timeout 5
```

## 被禁标志清单

| 标志 | 原因 |
|---|---|
| `-u` | URL 由配置根据经过校验的目标构建 |
| `-w` | 字典通过 --wordlist 传入 |
| `-o`, `-of` | 输出由 ffuf-cli 管理 |
| `-d` | 凭据相关的尝试（POST、数据、暴力破解）不属于本工具的范畴 |
| `-x` | HTTP 方法或代理：凭据相关的尝试（POST、数据、暴力破解）不属于本工具的范畴 |
| `-request`, `-request-proto` | 一个已保存的请求可能包含与经过校验的目标不同的主机 |
| `-mode` | 多字典模式用于凭据暴力破解 |
| `-replay-proxy` | 会把请求重新转发给第三方 |
| `-input-cmd` | 执行命令来生成输入 |
| `-r` | 跟随重定向可能跳转到作用域之外的主机 |
| `-preflight`, `-postflight` | 一个已保存的请求可能指向另一个主机 |
| `-config` | 配置文件可能改变 URL、方法和代理 |

## 过滤器做不到的事

它不是沙箱。想绕过它并不难，比如直接调用 `ffuf`。它的作用是拦住失误和坏习惯，而不是拦住一个已经能访问你终端的恶意人员。如果某项与客户约定好的活动需要用到被禁标志，请直接使用 ffuf，并在项目记录中注明这一选择。
