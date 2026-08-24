# 实体绘制集合证据

## 样本一致性

`小玩具105.ipa` 中热更程序集与本仓库恢复目标的 SHA-256 一致，因此以下 IL 结论适用于当前样本。

## 字段生命周期

| 字段 | 键类型 | IL 证据 | 结论 |
| --- | --- | --- | --- |
| `NLMAFONOFFH` | `UInt32` | `.ctor` 以 `0x400` 容量创建；`BPAJHFEOHGM` 创建事件写入；`JMOGCBFLNHL` 移除；`LBBNEPBIIPC` 场景卸载清空 | 主实体集合 |
| `CMPKHKEGCKK` | `Int32` | `JKNJMPNNMHD` 写入、`KBPAGCCMPHM` 查询 | 辅助索引 |
| `IMDDIDNCIPO` | `UInt32` | `EOOCLGLOFGJ` 写入、`DNIGPAHIDGK` 获取、`IHDFIPDPIJA` 移除 | 辅助索引 |

## 绘制快照入口

`JHDAFFFAKCK` 的 IL 明确执行 `NLMAFONOFFH.get_Values()`、`GetEnumerator()`、`get_Current()` 和 `List<DIGLCECMPAB>.Add()`，再返回该列表。绘制模块应调用此零参方法获得快照，而不是自行反射调用 `ValueCollection.Enumerator` 的值类型方法。

审计命令：

```powershell
dotnet run --project tools\EntityCollectionIlAnalysis\EntityCollectionIlAnalysis.csproj -- C:\Users\马思远\Desktop\kaifa\UpdateScript_500.dll
```

## 原插件地址对照

| 地址 | 已恢复行为 | 重构映射 |
| --- | --- | --- |
| `0x0723c4` | 主绘制调度，维护实体快照后发射标签 | 先取热更快照，再投影和筛选 |
| `0x066584` | 世界坐标到屏幕坐标并检查深度 | `Camera.WorldToScreenPoint` 与 `depth > 0` |
| `0x17332c` | 测量文本宽度后按中心绘制 | `UILabel` 居中对齐 |
| `0x18c8dc` | 左右各偏移 1px 深色描边，再绘制正文 | `RussOutlinedLabel` |

Metal 图元提交函数（`0x279198` 至 `0x27bad8`）属于原插件渲染后端；本重构继续使用应用内 UIKit 覆盖层，不把其私有 Metal 缓冲区布局带入新代码。
