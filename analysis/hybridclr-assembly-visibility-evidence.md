# HybridCLR 热更程序集可见性证据

## 已核验输入

- 目标 `UnityFramework`：`C:\Users\马思远\Desktop\kaifa\recovered\target\UnityFramework`
- 目标 `global-metadata.dat` SHA-256：`c317c73380c29fba336cf4bbad4114b5ed39c5f8c381ccb6187b209e4e2b8aaf`
- 热更 `updatescript_500.dll.ab` AssetBundle SHA-256：`58aaee78156e3fa671c957c77eb2da249bc1a4ee782a58fdbd39a0e4e54b4561`

其中 `58aa…4561` 是 AssetBundle 哈希，不是内部 PE 文件哈希。从该 AssetBundle 的
`UpdateScript_500.dll` TextAsset 解出的 PE 文件 SHA-256 是
`f1f1c6f0ea773b7200c5b016a6cbee40e1be116c0467d6eaa39356cc86fcadad`，与
`C:\Users\马思远\Desktop\kaifa\UpdateScript_500.dll` 完全一致。元数据哈希与两个可用基准 IPA
相同，因此 `OEPJBOIGGPO`、`DIGLCECMPAB` 和 `JHDAFFFAKCK` 的已审计 IL 结论仍适用于目标包。

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

## ScriptsStart.LoadDll 控制流

`dump.cs` 给出 `ScriptsStart.LoadDll(AssetBundle ab, AssetBundle aotAB)` 的 RVA 为 `0x4357998`。目标 UnityFramework 中该地址的 arm64 函数已直接反汇编核验：

1. 入口首先以 `aotAB` 参数进入 AOT 元数据加载分支，并调用本类的 `LoadMetadataForAOTAssemblies` 实现（RVA `0x435755c`）。
2. 后续从主脚本包取得程序集字节，经过托管程序集加载流程后才遍历脚本资源。
3. 任何一个阶段返回空对象或失败状态都会直接退出 `LoadDll`，不会把热更程序集注册到 `il2cpp_domain_get_assemblies` 的结果中。

目标 `il2cpp_domain_get_assemblies` 内部函数会遍历程序集注册链，仅复制状态字段非零的条目到返回向量。由此可得：`OEPJBOIGGPO` 未找到时，安全且唯一的下一步运行时判别是检查 `UpdateScript_500` 是否已注册；不能改用未注册程序集的内存地址、其他集合或字段。

当前 `FindClassInAllAssemblies` 未缓存空结果，并在每次绘制刷新时重试。因此它已经满足热更在稍后完成注册的时序要求；源码在得到实际失败阶段前保持不变。
