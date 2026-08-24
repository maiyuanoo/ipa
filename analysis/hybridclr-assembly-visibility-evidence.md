# HybridCLR 热更程序集可见性证据

## 已核验输入

- 目标 `UnityFramework`：`C:\Users\马思远\Desktop\kaifa\recovered\target\UnityFramework`
- 目标 `global-metadata.dat` SHA-256：`c317c73380c29fba336cf4bbad4114b5ed39c5f8c381ccb6187b209e4e2b8aaf`
- 热更程序集 `UpdateScript_500.dll` SHA-256：`58aaee78156e3fa671c957c77eb2da249bc1a4ee782a58fdbd39a0e4e54b4561`

元数据哈希与两个可用基准 IPA 相同，因此 `OEPJBOIGGPO`、`DIGLCECMPAB` 和 `JHDAFFFAKCK` 的已审计 IL 结论仍适用于目标包。

## UnityFramework 导出核验

用 `llvm-objdump` 对目标 arm64 Mach-O 的导出符号和函数体核验：

| 符号 | 地址 | 观察结果 |
| --- | ---: | --- |
| `_il2cpp_class_from_name` | `0x018857e8` | 跳转到 IL2CPP 类查找实现 |
| `_il2cpp_domain_get_assemblies` | `0x01885d7c` | 调用内部程序集列表获取函数，按连续 8 字节元素计算数量并写回 `size` |
| `hybridclr::metadata::RawImageBase::Load` | `0x0180251c` | 目标 UnityFramework 包含 HybridCLR 原始镜像加载实现 |

目标框架的字符串区同时包含 `HybridCLR.Runtime.dll` 和 `UpdateScript_500`。这证明目标包的热更机制存在，但不能仅凭静态字符串推出任意时刻的 `il2cpp_domain_get_assemblies` 返回值。

## 恢复结论

`RussNativeRecovered.c` 中的原插件类查找链已逐项与当前重构版对照：

```text
domain_get -> domain_get_assemblies -> assembly_get_image -> class_from_name
```

该链在原插件中逐个程序集逆序查询，当前重构版也是跨所有程序集查询；因此不能在没有新的运行时或反编译证据时，用内存扫描、固定地址或替代字段取代它。

`GD.dylib` 的恢复结果不使用这条链做其自身功能初始化，只能说明两个原插件的实现策略不同，不能否定上述原插件链。

下一步所需证据是运行时确认 `UpdateScript_500` 是否已经出现在程序集列表，或恢复 `ScriptsStart.LoadDll` 调用后的 HybridCLR 镜像注册实现。源码在此之前保持不变。
