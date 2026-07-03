"""
game_state.py - mod 状态文件读取与解析
"""
from __future__ import annotations

import json
import os
import re


def find_mod_files():
    """查找 mod 生成的文件位置"""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    save_dir = os.path.join(base_dir, "Save")
    patterns = [
        # 本地 Save 目录（优先）
        os.path.join(save_dir, "AIBotRecorder.player_state"),
        # 存档目录
        "C:/Users/wangte/Documents/Klei/DoNotStarveTogether/1106513728/Cluster_1/Master/save/AIBotRecorder.player_state",
    ]
    for path in patterns:
        if os.path.exists(path):
            print(f"✅ 找到状态文件: {path}")
            return path
    # 如果都不存在，返回本地 Save 目录
    first_path = patterns[0]
    try:
        os.makedirs(os.path.dirname(first_path), exist_ok=True)
    except:
        pass
    return first_path


MOD_STATE_FILE = find_mod_files()


def parse_incomplete_json(json_str):
    """解析不完整的JSON"""
    try:
        return json.loads(json_str)
    except:
        pass

    try:
        open_braces = json_str.count('{')
        close_braces = json_str.count('}')
        if open_braces > close_braces:
            json_str += '}' * (open_braces - close_braces)
            return json.loads(json_str)
    except:
        pass

    try:
        start = json_str.find('{')
        if start != -1:
            brace_count = 0
            for i in range(start, len(json_str)):
                if json_str[i] == '{':
                    brace_count += 1
                elif json_str[i] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        return json.loads(json_str[start:i + 1])
    except:
        pass

    print("❌ 无法解析JSON")
    return None


def parse_klei_state_file(file_path):
    """解析Klei格式的状态文件"""
    try:
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            content = f.read()

        if content.startswith('KLEI'):
            print("✅ 检测到Klei格式文件")
            match = re.search(r'KLEI\s*\d*\s*(\{.*)', content, re.DOTALL)
            if match:
                json_str = match.group(1).strip()
                open_braces = json_str.count('{')
                close_braces = json_str.count('}')
                if open_braces > close_braces:
                    json_str += '}' * (open_braces - close_braces)
                    print(f"⚠️ 补全了 {open_braces - close_braces} 个括号")

                data = json.loads(json_str)
                print("✅ JSON解析成功")
                return data
            else:
                print("⚠️ 未找到JSON数据")
                return None
        else:
            try:
                return json.loads(content)
            except:
                print("⚠️ 不是标准JSON格式")
                return None

    except UnicodeDecodeError:
        try:
            with open(file_path, 'r', encoding='latin-1') as f:
                content = f.read()
            match = re.search(r'KLEI\s*\d*\s*(\{.*)', content, re.DOTALL)
            if match:
                json_str = match.group(1).strip()
                open_braces = json_str.count('{')
                close_braces = json_str.count('}')
                if open_braces > close_braces:
                    json_str += '}' * (open_braces - close_braces)
                return json.loads(json_str)
        except:
            pass
    except Exception as e:
        print(f"❌ 解析失败: {e}")
    return None


def get_game_state():
    """从 mod 读取游戏状态"""
    if not os.path.exists(MOD_STATE_FILE):
        print(f"⚠️ 文件不存在: {MOD_STATE_FILE}")
        return None

    file_size = os.path.getsize(MOD_STATE_FILE)
    if file_size == 0:
        print("⚠️ 文件为空")
        return None

    print(f"📊 读取文件: {os.path.basename(MOD_STATE_FILE)} ({file_size} 字节)")

    data = parse_klei_state_file(MOD_STATE_FILE)

    if data:
        print("✅ 状态读取成功!")
        if 'player_pos' in data:
            pos = data['player_pos']
            print(f"   📍 玩家位置: ({pos.get('x', 0):.1f}, {pos.get('z', 0):.1f})")
        if 'health' in data:
            print(f"   ❤️ 生命: {data.get('health', 0)}%")
        if 'hunger' in data:
            print(f"   🍖 饥饿: {data.get('hunger', 0)}%")
        if 'sanity' in data:
            print(f"   🧠 精神: {data.get('sanity', 0)}%")
        if 'inventory' in data:
            print(f"   📦 物品: {len(data.get('inventory', []))}件")
        if 'nearby' in data:
            print(f"   👀 附近实体: {len(data.get('nearby', []))}个")
        return data
    else:
        print("❌ 状态读取失败")
        return None


def format_state_for_ai(state: dict) -> str:
    """格式化游戏状态给 AI 看"""
    if not state:
        return "【游戏状态】无数据"

    pos = state.get("player_pos", {})
    nearby = state.get("nearby", [])
    items = state.get("inventory", [])

    text = f"""【玩家位置】世界坐标: ({pos.get('x', 0):.1f}, {pos.get('z', 0):.1f})
【时间】{state.get('world_time', '?')} (第{state.get('world_day', 0)}天)
【属性】生命{state.get('health', 0)}% 饥饿{state.get('hunger', 0)}% 精神{state.get('sanity', 0)}%

【背包】({len(items)}件)"""
    for item in items[:6]:
        prefab = item.get('prefab', 'unknown')
        count = item.get('count', 1)
        text += f"\n- {prefab} x{count}"

    # 按距离排序，只显示最近的和重要的
    if nearby:
        text += f"\n\n【附近实体】(共{len(nearby)}个，按距离排序)"
        sorted_nearby = sorted(nearby, key=lambda e: e.get('dist', 999))[:12]
        for e in sorted_nearby:
            prefab = e.get('prefab', 'unknown')
            dist = e.get('dist', 0)
            x = e.get('x', 0)
            z = e.get('z', 0)
            text += f"\n- {prefab} 距{dist:.1f} 坐标({x:.1f}, {z:.1f})"

    return text
