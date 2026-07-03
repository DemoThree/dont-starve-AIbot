"""
dont_starve_bot.py
==================
饥荒 AI Bot - 结合截图 + mod 世界坐标精确定位

工作流程：
    1. 从 mod 读取游戏状态（玩家位置、附近实体世界坐标）
    2. 截图 + 游戏状态 + 实体坐标列表 发送给 AI
    3. AI 根据实体坐标决策，输出 world_x, world_z
    4. 世界坐标转屏幕坐标，点击目标
"""
from __future__ import annotations

import json
import os
import sys
import time

import pyautogui


from action import execute
from ai import ai_decide
from config import ACTION_INTERVAL, LOG_DIR, MAX_SCREENSHOTS, MINIMAX_API_KEY
from game_state import get_game_state
from screen import ScreenGrabber

# ============================================================
# 初始化
# ============================================================

if not MINIMAX_API_KEY:
    print("❌ 请设置 MINIMAX_API_KEY: set MINIMAX_API_KEY=你的key")
    sys.exit(1)

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.05


# ============================================================
# 游戏窗口
# ============================================================

def get_game_region():
    """获取饥荒游戏窗口位置"""
    try:
        for title in ["Don't Starve Together", "Don't Starve"]:
            wins = pyautogui.getWindowsWithTitle(title)
            if wins:
                w = wins[0]
                return (w.left, w.top, w.width, w.height)
    except Exception:
        pass
    return None


GAME_REGION = get_game_region()


# ============================================================
# 主循环
# ============================================================

def main():
    os.makedirs(LOG_DIR, exist_ok=True)
    grabber = ScreenGrabber(GAME_REGION)

    print("=" * 60)
    print("  饥荒 AI Bot")
    print("=" * 60)
    print(f"  窗口: {GAME_REGION or '全屏'}")
    print(f"  间隔: {ACTION_INTERVAL}s")
    print("=" * 60)

    frame = 0
    log_idx = 0
    log_path = os.path.join(LOG_DIR, f"run_{log_idx}.jsonl")
    log_f = open(log_path, "w", encoding="utf-8")

    try:
        while True:
            try:
                state = get_game_state()
                img = grabber.grab()
                # 保存截图到 logs 目录（轮换保存，只保留最新5张）
                screenshot_idx = frame % MAX_SCREENSHOTS
                screenshot_path = os.path.join(LOG_DIR, f"screenshot_{screenshot_idx}.png")
                img.save(screenshot_path)
                decision = ai_decide(img, state)
                execute(decision, grabber, state)

                log_f.write(json.dumps({
                    "frame": frame,
                    "decision": decision,
                    "state": state,
                    "time": time.time(),
                }, ensure_ascii=False) + "\n")
                log_f.flush()
                # 达到最大帧数则清空重新开始（覆盖）
                if frame > 0 and frame % 1000 == 0:
                    log_f.close()
                    log_f = open(log_path, "w", encoding="utf-8")

                frame += 1
                time.sleep(ACTION_INTERVAL)

            except pyautogui.FailSafeException:
                print("\n🛑 FAILSAFE")
                break
            except KeyboardInterrupt:
                print("\n🛑 退出")
                break
            except Exception as e:
                print(f"\n⚠️ {type(e).__name__}: {e}")
                time.sleep(2)
    finally:
        for k in ("w", "a", "s", "d"):
            pyautogui.keyUp(k)
        log_f.close()
        print(f"\n📝 {log_path}")


if __name__ == "__main__":
    main()
