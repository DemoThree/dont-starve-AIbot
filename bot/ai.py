"""
ai.py - AI 决策
"""
from __future__ import annotations

import json
from typing import Any

from openai import OpenAI
from PIL import Image

from config import MINIMAX_API_KEY, MINIMAX_BASE_URL, VISION_MODEL
from game_state import format_state_for_ai
from screen import img_to_b64

client = OpenAI(api_key=MINIMAX_API_KEY, base_url=MINIMAX_BASE_URL)

SYSTEM_PROMPT = """你是 Don't Starve（饥荒）的高手 Wilson。

【控制方式】
- WASD：移动
- 鼠标左键：采集/交互
- 鼠标右键：攻击
- E：背包 T：制作 M：地图

【坐标系统】
- 你会收到【玩家世界坐标】和【附近实体列表】
- 实体坐标是(world_x, world_z)格式
- 点击时用 left_click/riwght_click + world_x + world_z

【决策规则】
1. 优先采集最近的资源（草、树枝、燧石、浆果）
2. 使用提供的实体坐标，和图片,不要自己猜
3. 移动用 world_x/world_z 让系统转换
4. thought 不超过 15 字
5. 【重要】绝对不要返回 do_nothing！即使没有明确目标，也要移动探索或采集任意可见资源

【附近实体类型】
- grass：草（采集得草纤维）
- twigs：树枝（采集得树枝）
- flint：燧石（重要工具材料）
- berries：浆果丛（采集得浆果）
- carrot：胡萝卜（食物）
- rocks：石头（重要材料）
- trees：树（砍伐得木头）
- spider：蜘蛛（危险，攻击或躲避）"""

ACTION_SCHEMA = {
    "type": "object",
    "properties": {
        "action": {
            "type": "string",
            "enum": [
                "move_up", "move_down", "move_left", "move_right",
                "stop_move", "left_click", "right_click",
                "open_inventory", "open_crafting", "open_map",
                "pause", "do_nothing"
            ],
        },
        "thought": {"type": "string", "description": "决策理由（≤15字）"},
        "duration_ms": {"type": "integer", "description": "移动持续ms"},
        "world_x": {"type": "number", "description": "目标世界坐标X"},
        "world_z": {"type": "number", "description": "目标世界坐标Z"},
    },
    "required": ["action", "thought"],
}

GAME_ACTION_TOOL = {
    "type": "function",
    "function": {
        "name": "game_action",
        "description": "在饥荒执行动作",
        "parameters": ACTION_SCHEMA,
    },
}


def parse_ai_response(args_str: str, state: dict = None) -> dict:
    """解析 AI 返回"""
    if not args_str:
        return _fallback_action(state, "空响应")

    # 清理常见问题字符
    args_str = args_str.strip()
    # 去掉可能的 markdown 代码块
    if args_str.startswith("```"):
        args_str = args_str.strip("`")
        # 去掉 json 前缀
        for prefix in ("json", "JSON"):
            if args_str.startswith(prefix):
                args_str = args_str[len(prefix):].strip()

    try:
        data = json.loads(args_str)
        action = data.get("action", "")

        # 如果是 do_nothing 或无效动作，使用降级策略
        if action == "do_nothing" or not action:
            return _fallback_action(state, data.get("thought", "强制决策"))

        return data
    except json.JSONDecodeError as e:
        print(f"⚠️ JSON解析失败: {e}, 原始内容: {args_str[:200]}")
        return _fallback_action(state, "解析失败")


def _fallback_action(state: dict, reason: str) -> dict:
    """当 AI 返回 do_nothing 或解析失败时，强制做出决策"""
    import random

    entities = state.get("entities", []) if state else []

    if entities:
        # 随机选择一个实体进行交互
        target = random.choice(entities)
        entity_type = target.get("type", "")
        wx, wz = target.get("x", 0), target.get("z", 0)

        if entity_type in ("grass", "twigs", "berries", "carrot"):
            return {
                "action": "left_click",
                "thought": f"采集{entity_type}",
                "world_x": wx,
                "world_z": wz,
            }
        elif entity_type in ("flint", "rocks"):
            return {
                "action": "left_click",
                "thought": f"采集{entity_type}",
                "world_x": wx,
                "world_z": wz,
            }
        elif entity_type == "spider":
            return {
                "action": "right_click",
                "thought": "攻击蜘蛛",
                "world_x": wx,
                "world_z": wz,
            }

    # 没有实体或随机决定，移动探索
    directions = ["move_up", "move_down", "move_left", "move_right"]
    direction = random.choice(directions)
    return {
        "action": direction,
        "thought": "探索环境",
        "duration_ms": 500,
    }


def ai_decide(img: Image.Image, state: dict) -> dict:
    """AI 根据截图和游戏状态决策"""
    img_b64 = img_to_b64(img)
    state_text = format_state_for_ai(state)

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": [
            {"type": "text", "text": f"{state_text}\n\n根据以上状态选择动作，只用提供的坐标！"},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}}
        ]}
    ]

    resp = client.chat.completions.create(
        model=VISION_MODEL,
        messages=messages,
        tools=[GAME_ACTION_TOOL],
        tool_choice={"type": "function", "function": {"name": "game_action"}},
        max_tokens=300,
        temperature=0.4,
    )

    msg = resp.choices[0].message
    if not msg.tool_calls:
        return _fallback_action(state, msg.content or "无响应")

    return parse_ai_response(msg.tool_calls[0].function.arguments, state)
