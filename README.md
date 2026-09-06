# Roleplay Chat（Flutter / iOS）

本地优先的 AI 角色扮演聊天 App。界面使用 Flutter，消息、长期记忆和关系数值保存在设备内的 SQLite；支持 OpenAI、DeepSeek 和自定义 OpenAI 兼容接口。

## 已实现

- 从 `assets/persona.json` 读取名字、性格、说话风格和背景故事。
- 每次请求携带角色设定、关系状态、长期记忆、Live State 和最近 20 轮对话。
- 每轮回复后调用一次 JSON 关系评估，更新熟悉度、信任感、好感度和芥蒂感。
- 关系值限制为 0–100，单轮变化限制为 -5–5。
- 超过 20 轮后，把最早 5 轮与已有长期记忆合并为约 200 字摘要；成功写入后才删除原文。
- API Key 使用 iOS Keychain 对应的加密存储，不写入 SQLite 或源码。
- 关系评估或记忆压缩失败不会丢失已完成的聊天。

## 本地测试

```bash
flutter pub get
flutter analyze
flutter test
```

测试使用内存 SQLite 和模拟 API，不会产生真实 API 费用。

## GitHub Actions 构建

工作流位于 `.github/workflows/ios.yml`。推送代码后会自动：

1. 运行静态检查和全部 Flutter 测试。
2. 在 GitHub 的 macOS runner 上执行无签名 iOS Release 构建。
3. 生成 `RoleplayChat-unsigned-ipa` Artifact。

无签名 IPA 适合验证构建结果，但不能直接安装到普通未越狱 iPhone。

### 生成可安装的签名 IPA

在 GitHub 仓库的 `Settings → Secrets and variables → Actions` 中添加：

Secrets：

- `BUILD_CERTIFICATE_BASE64`：`.p12` 证书文件的 Base64 文本
- `P12_PASSWORD`：导出 `.p12` 时设置的密码
- `BUILD_PROVISION_PROFILE_BASE64`：`.mobileprovision` 文件的 Base64 文本
- `KEYCHAIN_PASSWORD`：任意新生成的随机密码，仅用于 CI 临时钥匙串

Variables：

- `ENABLE_SIGNED_IPA`：设为 `true`
- `IOS_EXPORT_METHOD`：通常为 `development`、`ad-hoc` 或 `app-store-connect`

工作流会从 provisioning profile 自动读取 Team ID、Bundle ID、UUID 和 Profile Name，导入临时钥匙串并运行 `flutter build ipa`。成功后在该次 Actions Run 的 Artifacts 中下载 `RoleplayChat-signed-ipa`。

在 PowerShell 中可用以下方式把证书复制为 Base64：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('certificate.p12')) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes('profile.mobileprovision')) | Set-Clipboard
```

Base64 只是编码，不是加密；只应把结果放进 GitHub Secrets，不要提交到仓库。

## 修改角色

编辑 `assets/persona.json`：

```json
{
  "name": "角色名",
  "personality": "性格",
  "speaking_style": "说话风格",
  "background": "背景故事"
}
```

## API 设置

首次打开 App，点击右上角设置按钮：

- OpenAI 默认地址：`https://api.openai.com/v1`
- DeepSeek 默认地址：`https://api.deepseek.com`
- 也可以填写自定义 HTTPS 地址和模型名

公开分发时，不建议让所有用户共用一个写死在客户端的 API Key。当前版本让每位用户在设备上填写自己的 Key；商业发布建议增加受认证的后端代理。

