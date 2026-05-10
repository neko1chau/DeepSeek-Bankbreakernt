# DeepSeek-Bankbreakernt

实际上不知道干了什么，全部让 OpenCode Vibe 的，主要用来监控 DeepSeek 余额，Swift 写的。

图标还没来得及搞，功能应该基本 OK 了。

1.0.1 更新

安全加固：API Key 迁移到 Keychain，启用 App Sandbox，修复 Logger 隐私泄露
- CredentialsStore 改用 Keychain 存储 API Key，替换明文 UserDefaults
- 新增 KeychainStore 封装 Keychain Services 读写
- 启用 App Sandbox，添加网络客户端权限
- Logger os_log 参数从 %{public}c 改为 %{private}c 防止系统日志泄露
