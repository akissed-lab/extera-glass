#!/usr/bin/env python3
"""Извлекает темы ExteraGram из APK и генерирует Swift-токены.

Источник: assets/*.attheme внутри exteraGram-full-universal-20261102.apk.
Выход: ExteraGlass/Theme/ThemeTokens.swift
"""
from __future__ import annotations

import os
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APK = ROOT.parent / "exteraGram-full-universal-20261102.apk"
OUT = ROOT / "ExteraGlass" / "Theme" / "ThemeTokens.swift"

# Material You тональные палитры (приближение к ThatPage/ExteraGram monet-темам).
PALETTES: dict[str, dict[int, str]] = {
    "n1": {
        0: "FFFFFF", 10: "FDFCFF", 50: "E5E1E6", 100: "CCC8CF", 200: "A6A2AA",
        300: "7F7B84", 400: "5A5760", 500: "454248", 600: "312F35", 700: "222127",
        800: "1A191E", 900: "131216", 1000: "000000",
    },
    "n2": {
        0: "FFFFFF", 10: "FDFCFF", 50: "E6E1E8", 100: "CEC9D0", 200: "A8A3AB",
        300: "817C85", 400: "5C5760", 500: "474248", 600: "332E35", 700: "232027",
        800: "1B181F", 900: "141116", 1000: "000000",
    },
    "a1": {
        0: "FFFFFF", 10: "E8F0FE", 50: "D3E3FD", 100: "B7D4FB", 200: "97C1F9",
        300: "73A7F4", 400: "528CEF", 500: "3B72E7", 600: "2959D3", 700: "1E47AF",
        800: "1B3B8B", 900: "1A3368", 1000: "001B3E",
    },
    "a2": {
        0: "FFFFFF", 10: "F9ECFF", 50: "F2DBFF", 100: "E9BBFF", 200: "DC97FF",
        300: "CB6FF3", 400: "B747E5", 500: "9E28CE", 600: "8120AC", 700: "671B8A",
        800: "551873", 900: "3F1457", 1000: "260533",
    },
    "a3": {
        0: "FFFFFF", 10: "FFF8E1", 50: "FFEFC0", 100: "FFE295", 200: "FFD166",
        300: "F9BC37", 400: "ECA30B", 500: "CE8500", 600: "A96700", 700: "824C00",
        800: "673C00", 900: "4F2E00", 1000: "2F1A00",
    },
}

#人类可读名称 + тёмная ли тема
THEMES: list[tuple[str, str, bool]] = [
    ("day", "Day", False),
    ("night", "Night", True),
    ("darkblue", "Dark Blue", True),
    ("arctic", "Arctic", False),
    ("bluebubbles", "Blue Bubbles", False),
    ("monet_light", "Monet Light", False),
    ("monet_dark", "Monet Dark", True),
    ("monet_black", "Monet Black", True),
]

# semantic Swift key -> список ключей .attheme по приоритету
FIELDS: dict[str, list[str]] = {
    "accent": ["telegram_color", "key_telegram_color", "dialogTextBlue", "chat_outBubble"],
    "background": ["windowBackgroundWhite", "chats_menuBackground"],
    "surface": ["windowBackgroundWhite", "chats_menuBackground"],
    "surfaceElevated": ["windowBackgroundWhite", "dialogBackground"],
    "navigationBar": ["actionBarDefault", "windowBackgroundWhite"],
    "navigationTitle": ["actionBarDefaultTitle", "dialogTextBlack"],
    "primaryText": ["dialogTextBlack", "chats_name", "windowBackgroundWhiteBlackText"],
    "secondaryText": ["chats_nameMessage", "dialogTextGray", "chats_name"],
    "incomingBubble": ["chat_inBubble", "chat_inFileBackground"],
    "outgoingBubble": ["chat_outBubble", "chat_outFileBackground"],
    "incomingText": ["chat_inText", "chat_messageTextIn", "dialogTextBlack"],
    "outgoingText": ["chat_outText", "chat_messageTextOut", "dialogTextBlack"],
    "timeText": ["chat_outTimeText", "chat_inTimeText", "chats_date"],
    "serviceBubble": ["chat_serviceBackground", "chat_serviceText"],
    "inputBackground": ["chat_messagePanelBackground", "windowBackgroundWhite"],
    "chatBackground": ["chat_wallpaper", "windowBackgroundWhite"],
    "divider": ["divider", "chat_serviceBackground", "windowBackgroundWhite"],
}

FALLBACKS: dict[str, tuple[str, str]] = {
    # key: (light, dark)
    "accent": ("#FF3390EC", "#FF3390EC"),
    "background": ("#FFFFFFFF", "#FF17212B"),
    "surface": ("#FFFFFFFF", "#FF1E2C3A"),
    "surfaceElevated": ("#FFF5F5F5", "#FF243343"),
    "navigationBar": ("#FFFFFFFF", "#FF17212B"),
    "navigationTitle": ("#FF1C1C1C", "#FFFFFFFF"),
    "primaryText": ("#FF1C1C1C", "#FFFFFFFF"),
    "secondaryText": ("#FF7F7F7F", "#FF8A9AA8"),
    "incomingBubble": ("#FFF0F0F0", "#FF243343"),
    "outgoingBubble": ("#FFE3FFC7", "#FF2B5278"),
    "incomingText": ("#FF1C1C1C", "#FFFFFFFF"),
    "outgoingText": ("#FF1C1C1C", "#FFFFFFFF"),
    "timeText": ("#FF8A8A8A", "#FF8A9AA8"),
    "serviceBubble": ("#FFE8E8E8", "#FF2B3B4A"),
    "inputBackground": ("#FFFFFFFF", "#FF1E2C3A"),
    "chatBackground": ("#FFFFFFFF", "#FF17212B"),
    "divider": ("#FFE5E5E5", "#FF2B3B4A"),
}

TOKEN_RE = re.compile(r"^(n[123]_\d+|mBlack|mWhite)\s*(.*)$")
ALPHA_RE = re.compile(r"\(a\s*=\s*(\d+)")


def argb_to_hex(value: str) -> str:
    n = int(value)
    if n < 0:
        n += 1 << 32
    return f"#{n & 0xFFFFFFFF:08X}"


def monet_to_hex(value: str) -> str:
    m = TOKEN_RE.match(value.strip())
    if not m:
        return value
    token, modifiers = m.group(1), m.group(2)
    alpha_match = ALPHA_RE.search(modifiers)
    alpha = int(alpha_match.group(1)) if alpha_match else 100
    if token == "mBlack":
        rgb = "000000"
    elif token == "mWhite":
        rgb = "FFFFFF"
    else:
        family, tone = token.split("_")
        rgb = PALETTES.get(family, PALETTES["n1"]).get(int(tone), "808080")
    a = max(0, min(255, round(alpha * 255 / 100)))
    return f"#{a:02X}{rgb}"


def normalize(value: str) -> str:
    value = value.strip()
    if re.fullmatch(r"-?\d+", value):
        return argb_to_hex(value)
    if TOKEN_RE.match(value):
        return monet_to_hex(value)
    return value


def load_themes() -> dict[str, dict[str, str]]:
    if not APK.exists():
        raise SystemExit(f"APK не найден: {APK}")
    result: dict[str, dict[str, str]] = {}
    with zipfile.ZipFile(APK) as zf:
        for file_name, _, _ in THEMES:
            path = f"assets/{file_name}.attheme"
            if path not in zf.namelist():
                print(f"⚠ Нет в APK: {path}")
                continue
            raw = zf.read(path).decode("utf-8", errors="replace")
            pairs: dict[str, str] = {}
            for line in raw.splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    pairs[k.strip()] = v.strip()
            result[file_name] = pairs
    return result


def generate() -> None:
    themes = load_themes()
    lines = [
        "// Сгенерировано tools/extract_themes.py из exteraGram-full-universal-20261102.apk",
        "// НЕ редактируйте вручную — перезапустите скрипт.",
        "",
        "import Foundation",
        "",
        "enum ThemeTokens {",
        "    static let all: [String: [String: String]] = [",
    ]
    for file_name, display, is_dark in THEMES:
        pairs = themes.get(file_name, {})
        dark = "true" if is_dark else "false"
        lines.append(f'        "{file_name}": [')
        lines.append(f'            "displayName": "{display}",')
        lines.append(f'            "isDark": "{dark}",')
        for field, candidates in FIELDS.items():
            value = None
            for candidate in candidates:
                if candidate in pairs:
                    value = normalize(pairs[candidate])
                    break
            if value is None:
                value = FALLBACKS[field][1 if is_dark else 0]
            if not value.startswith("#"):
                value = FALLBACKS[field][1 if is_dark else 0]
            lines.append(f'            "{field}": "{value}",')
        lines.append("        ],")
    lines += ["    ]", "}", ""]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Готово: {OUT} ({len(themes)} тем)")


if __name__ == "__main__":
    generate()
