# 目标弱加载插件身份核验

## 样本

- IPA：`C:\Users\马思远\Desktop\ipa\小玩具105.ipa`
- IPA 条目：`Payload/Origin.app/Frameworks/iOS·Origin.dylib`
- 解压后的 SHA-256：`e0a7df895b81a8bb471a81f3079018868706934f69c82c24ab197fe91ff8ce91`
- 现有实体绘制反编译输入：`analysis/input/Ciyue0818.dylib`
- 现有输入 SHA-256：`e7b0e578c249f161a97e007d87b780a077601c4c6b3fef47da717d35935b6a16`

## 可复现检查

使用 `System.IO.Compression.ZipFile` 枚举 IPA 条目，包内仅存在一个以 `.dylib` 结尾的文件：

```text
Payload/Origin.app/Frameworks/iOS·Origin.dylib
```

两个 SHA-256 不同，因此 `iOS·Origin.dylib` 不是 `Ciyue0818.dylib` 的同一二进制文件。

对两个文件提取可打印字符串后，`Ciyue0818.dylib` 包含
`/UnityFramework.framework/UnityFramework`、`il2cpp_domain_get`、
`il2cpp_class_get_image` 等运行时解析符号；目标 `iOS·Origin.dylib` 不包含这些字符串。

## 结论与约束

`iOS·Origin.dylib` 是目标主程序弱加载的文件名依据，因而重建产物必须保持该文件名。
但它不能作为现有实体快照和 IL2CPP 类查询实现的等价反编译样本，也不能据此替换
`Ciyue0818.dylib` 已恢复并由 `UpdateScript_500.dll` IL 交叉验证的调用链。

在获得与 `Ciyue0818.dylib` 相同功能的原始样本，或取得新的运行时可观察证据前，不修改
`RussRebuilt.m` 的实体类、字段、方法或内存读取路径。
