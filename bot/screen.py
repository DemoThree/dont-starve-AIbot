"""
screen.py - 屏幕截图
"""
from __future__ import annotations

import base64
import io

import mss
from PIL import Image

from config import MAX_SCREEN_SIDE


class ScreenGrabber:
    def __init__(self, region):
        self.region = region
        self.sct = mss.MSS()
        if region:
            self.monitor = {"left": region[0], "top": region[1], "width": region[2], "height": region[3]}
        else:
            self.monitor = self.sct.monitors[1]
        self.width = self.monitor["width"]
        self.height = self.monitor["height"]
        self.scale = min(1.0, MAX_SCREEN_SIDE / max(self.width, self.height))

    def grab(self) -> Image.Image:
        raw = self.sct.grab(self.monitor)
        img = Image.frombytes("RGB", raw.size, raw.bgra, "raw", "BGRX")
        if self.scale < 1.0:
            img = img.resize((int(self.width * self.scale), int(self.height * self.scale)), Image.LANCZOS)
        return img

    def real_xy(self, x: int, y: int) -> tuple:
        """截图坐标 -> 实际屏幕坐标"""
        return (
            self.monitor["left"] + int(x * self.scale),
            self.monitor["top"] + int(y * self.scale),
        )


def img_to_b64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return base64.b64encode(buf.getvalue()).decode()
