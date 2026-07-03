# 数据模型：S/theta/u/y/T/O

本项目把游戏逻辑看成一个闭合模型：

```text
(S', O) = T(S, u, y, theta)
```

源码文件只允许属于 `S`、`theta`、`u`、`y`、`T` 五类。`O` 不建目录，也不放函数；它只是 `T` 产生出来的数据、返回值或界面状态。

## 映射关系

- `S_p` 玩家进度状态：`Strength`、`Trophies`、`Exp`、`RebirthCount`、`CurrentBarbellId`、`BodyQuality`、`OwnedPets`、`EquippedPetInstanceIds`、`NextPetInstanceId`。
- `S_r` 服务端运行时状态：`IsMoving`、`AutoAreaContacts`、`GrowthLoopActive`、`LastPetRollTime`。
- `theta` 规则参数：自动区、杠铃、宠物、宠物蛋、宠物系统、身体素质、重生、等级经验、初始状态、Remote 协议。
- `u` 输入适配：Remote、玩家生命周期、客户端移动、区域触碰声明、E 键切换杠铃请求、宠物蛋抽奖请求、宠物装备请求。
- `y` 观测验证：服务端 Workspace 空间查询、角色 RootPart 状态、区域 id 合法性、杠铃展示距离验证、宠物蛋交互距离验证。
- `T` 状态转移：初始化、清理、移动更新、区域接触确认、训练结算、重生、杠铃切换、宠物抽奖、宠物装备、奖杯奖励、快照生成、UI 渲染。
- `O` 输出数据：玩家数据快照、重生响应、杠铃切换响应、宠物抽奖响应、宠物装备响应、客户端 UI 实例和文本状态。

## 所有权

- `S/PlayerProgressState.lua` 拥有 `S_p`，只提供 `Init(player, state)`、`Remove`、`Get`、`Set`。
- `S/TrainingRuntimeState.lua` 拥有 `S_r`，只提供 `Init(player, state)`、`Remove`、`Get`、`Set`。
- `S` 不读取 `theta`，不认识字段业务含义，不负责状态是否合法；它只隔离保存和复制状态。
- `theta/*.lua` 只保存参数表，不保存玩家状态，不访问 Workspace，不执行业务转移。
- `y/*.lua` 把不可信声明或 Workspace 查询转成服务端观测结果，不写状态。
- `u/*.lua` 只接输入并调用 `T`，不能直接写 `S`。
- `T/*.lua` 是唯一能根据 `S`、`u`、`y`、`theta` 产生 `S'` 和 `O` 的层。
- `T` 可以创建临时局部值，但长期事实只能写回 `S`，规则参数只能来自 `theta`，观测事实只能来自 `y`。

## T 内部分类

- `T/Transitions`：会写 `S_p` 或 `S_r` 的状态转移。检查重点是反作弊、原子性和不变量。
- `T/Rules`：只根据输入和 `theta` 计算规则结果，不写 `S`，不访问 Workspace。
- `T/Snapshots`：只把 `S` 和 `theta` 推导成客户端需要的 `O`，不写 `S`。
- `T/WorldSync`：只负责 Workspace 里的模型、Prompt、触碰绑定和视觉同步，不决定玩家长期事实。
- 根目录旧 `T/*.lua` 只保留兼容入口；新逻辑应优先放进上面四类目录。

## 派生值

这些值不作为核心状态保存：

- `Level`
- `MaxLevel`
- `MaxExp`
- `CanRebirth`
- `AutoAreaMultiplier` 从服务端确认的区域接触、自动区配置和 `RebirthCount` 推导。
- `BarbellMultiplier`
- `BarbellRequiredTrophies`
- `PetMultiplier`

这些计算都在 `T` 内部完成。`FormulaService`、`LevelService` 不再作为独立架构类别存在。
训练收益和增长决策使用直接返回值传递，不再创建 `growthContext`、`gains` 这类隐形数据模型。

## 宠物抽奖合同

- 宠物蛋是抽宠入口，不是宠物本身。
- 客户端可以本地检测碰到宠物蛋、按下 `E`、渲染抽奖 UI；这些只属于交互体验，不是可信事实。
- 客户端发起抽奖时只能提交 `eggId`，不能提交抽中宠物、倍率、稀有度或消耗数量。
- 服务端在购买瞬间通过 `y` 重新验证 `eggId` 和玩家与宠物蛋的距离。
- 抽奖随机性只在服务端 `T` 内发生，奖池和概率只来自 `theta`。
- `S_p.OwnedPets` 是玩家拥有宠物实例的唯一真相，使用字符串实例 id 作为字典 key。
- 宠物实例 id 在单个玩家内部递增生成，`NextPetInstanceId` 保存下一个可用编号。
- 每个宠物实例当前只保存 `InstanceId` 和 `PetTypeId`；名字、稀有度、倍率从 `theta.PetTheta` 推导。
- `S_p.EquippedPetInstanceIds` 是固定三个槽位，空槽使用 `0`。
- 同种宠物可以重复拥有和重复装备，但同一个宠物实例不能同时占用多个槽位。
- 抽到宠物后只进入背包，不自动装备。
- 宠物倍率按装备槽中的不同宠物实例倍率相加；没有装备宠物时宠物倍率为 `1`。
- 全部宠物蛋共享抽奖冷却，运行时冷却事实保存在 `S_r.LastPetRollTime`。

## 不变量

- `Strength >= 0`
- `Trophies >= 0`
- `Exp >= 0`
- `Exp <= MaxExp(RebirthCount)`
- `RebirthCount >= 0`
- `AutoAreaContacts` 只能包含 `theta.AutoAreaTheta` 里存在的区域 id。
- 客户端 Remote 只能触发状态转移，不能直接写 `S_p` 或 `S_r`。
- 自动区倍率必须来自服务端验证过、且玩家已解锁的区域接触。
- 同时接触多个自动区时，只取已解锁区域里的最高倍率。
