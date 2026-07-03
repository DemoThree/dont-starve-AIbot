"""
config.py - 配置常量
"""
from __future__ import annotations

import os

MINIMAX_API_KEY = os.getenv("MINIMAX_API_KEY")
MINIMAX_BASE_URL = os.getenv("MINIMAX_BASE_URL", "https://api.minimax.chat/v1")
VISION_MODEL = os.getenv("MINIMAX_VISION_MODEL", "MiniMax-M2.7-highspeed")

# 决策间隔（秒）
ACTION_INTERVAL = 1.5

# 截图最大边长
MAX_SCREEN_SIDE = 1024

# 日志目录
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
MAX_SCREENSHOTS = 5  # 最多保留最新5张截图
