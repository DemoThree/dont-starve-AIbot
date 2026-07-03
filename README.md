# Don't Starve AI Bot

饥荒联机版 AI Bot — 结合截图 + mod 世界坐标精确定位实现自动化游戏。

## 功能

- **视觉 AI 决策**：截图 + 游戏状态发送给 AI，AI 输出目标世界坐标
- **坐标精准定位**：通过 mod 获取实体世界坐标，解决纯视觉定位误差问题
- **自动操作**：世界坐标转屏幕坐标，自动点击移动到目标位置
- **行为日志**：保存每帧决策和游戏状态到日志文件

## 项目结构

```
bot/
├── dont_starve_bot.py   # 主程序入口
├── ai.py                # AI 决策模块
├── action.py            # 行动执行模块
├── screen.py            # 截图模块
├── game_state.py        # 游戏状态读取（从 mod 获取）
├── config.py            # 配置常量
├── mods/
│   └── AIBotRecorder/   # 饥荒 mod，导出玩家位置和实体坐标
│       ├── modinfo.lua
│       └── modmain.lua
└── logs/                # 运行日志和截图
```

## 依赖

```bash
pip install pyautogui pillow
```

## 配置

设置 MiniMax API Key：

```bash
# Windows
set MINIMAX_API_KEY=你的key

# Linux/macOS
export MINIMAX_API_KEY=你的key
```

可选环境变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MINIMAX_API_KEY` | 必填 | MiniMax API Key |
| `MINIMAX_BASE_URL` | `https://api.minimax.chat/v1` | API 地址 |
| `MINIMAX_VISION_MODEL` | `MiniMax-M2.7-highspeed` | 视觉模型 |

## 安装 Mod

1. 将 `bot/mods/AIBotRecorder` 复制到饥荒 mod 目录：
   ```
   Documents/Klei/DoNotStarveTogether/<cluster>/mods/
   ```
2. 在游戏 mods 菜单中启用 **AIBotRecorder**

## 运行

```bash
cd bot
python dont_starve_bot.py
```

## 工作流程

```
1. mod 读取游戏状态（玩家位置、附近实体世界坐标）
2. 截图 + 游戏状态 + 实体坐标列表 发送给 AI
3. AI 根据实体坐标决策，输出 world_x, world_z
4. 世界坐标转屏幕坐标，点击目标位置
```

## 安全

- 按住鼠标中键或四角移动鼠标可触发 pyautogui FAILSAFE 紧急停止
- `Ctrl+C` 也可安全退出

## 日志

运行日志保存在 `bot/logs/run_N.jsonl`，包含每帧的决策和游戏状态。
