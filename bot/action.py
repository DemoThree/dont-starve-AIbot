"""
action.py - 坐标转换与动作执行
"""
from __future__ import annotations

import time

import pyautogui

from screen import ScreenGrabber

KEY_MAP = {
    "move_up": "w", "move_down": "s", "move_left": "a", "move_right": "d",
    "open_inventory": "e", "open_crafting": "t", "open_map": "m", "pause": "space",
}


def world_to_screen(world_x: float, world_z: float,
                    player_x: float, player_z: float,
                    screen_w: int, screen_h: int,
                    offset_x: int, offset_y: int) -> tuple[int, int]:
    """
    世界坐标 -> 屏幕坐标
    饥荒是俯视角，world_x 向右，world_z 向下
    """
    dx = world_x - player_x
    dz = world_z - player_z

    # 像素缩放比（需要根据实际调整）
    SCALE = 50

    screen_x = int(screen_w / 2 + dx * SCALE)
    screen_y = int(screen_h / 2 + dz * SCALE)

    # 加窗口偏移
    real_x = offset_x + screen_x
    real_y = offset_y + screen_y

    return real_x, real_y


def execute(action: dict, grabber: ScreenGrabber, state: dict):
    name = action.get("action", "do_nothing")
    thought = action.get("thought", "")

    if name == "do_nothing":
        print(f"\n⚠️ AI 返回 do_nothing: {thought}，跳过执行")
        return

    print(f"\n🤖 {thought} → {name}")

    if name in KEY_MAP:
        key = KEY_MAP[name]
        if name in ("pause", "open_inventory", "open_crafting", "open_map"):
            pyautogui.press(key)
        else:
            dur = max(100, min(int(action.get("duration_ms", 500)), 3000)) / 1000.0
            pyautogui.keyDown(key)
            time.sleep(dur)
            pyautogui.keyUp(key)

    elif name in ("left_click", "right_click"):
        wx = action.get("world_x")
        wz = action.get("world_z")

        player_pos = state.get("player_pos", {}) if state else {}
        px, pz = player_pos.get("x", 0), player_pos.get("z", 0)

        if wx is not None and wz is not None:
            rx, ry = world_to_screen(wx, wz, px, pz,
                                     grabber.width, grabber.height,
                                     grabber.monitor["left"], grabber.monitor["top"])
            print(f"   📍 世界({wx:.1f},{wz:.1f}) → 屏幕({rx},{ry})")
        else:
            # 没有世界坐标，用屏幕中心
            rx, ry = grabber.real_xy(grabber.width // 2, grabber.height // 2)
            print(f"   ⚠️ 无世界坐标，用中心({rx},{ry})")

        btn = "left" if name == "left_click" else "right"
        pyautogui.click(rx, ry, button=btn)

    elif name == "stop_move":
        for k in ("w", "a", "s", "d"):
            pyautogui.keyUp(k)
