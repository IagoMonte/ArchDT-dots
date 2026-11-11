#!/usr/bin/env python3
import argparse
import re
import os
from typing import Dict, List


COLUMN_MARKER = "-- >>>"  # Títulos grandes (colunas)
SECTION_MARKER = "-- >>"   # Subtítulos (seções)
HIDE_COMMENT = "[hidden]"
MOD_SEPARATORS = ['+', ' ']
COMMENT_BIND_PATTERN = "--/#"


parser = argparse.ArgumentParser(description='Hyprland keybind reader')
parser.add_argument('--path', type=str, default="$HOME/.config/hypr/conf/binds.lua", help='path to keybind file')
args = parser.parse_args()
content_lines = []
reading_line = 0


class KeyBinding(dict):
    def __init__(self, mods, key, dispatcher, params, comment) -> None:
        self["mods"] = mods
        self["key"] = key
        self["dispatcher"] = dispatcher
        self["params"] = params
        self["comment"] = comment


class Section(dict):
    def __init__(self, children, keybinds, name) -> None:
        self["children"] = children
        self["keybinds"] = keybinds
        self["name"] = name


def read_content(path: str) -> str:
    if not os.access(os.path.expanduser(os.path.expandvars(path)), os.R_OK):
        return "error"
    with open(os.path.expanduser(os.path.expandvars(path)), "r") as file:
        return file.read()


def autogenerate_comment(dispatcher: str, params: str = "") -> str:
    match dispatcher:
        case "resizewindow":
            return "Resize window"
        case "movewindow":
            if params == "":
                return "Move window"
            else:
                return "Window: move in {} direction".format({
                    "l": "left", "r": "right", "u": "up", "d": "down",
                }.get(params, "null"))
        case "pin":
            return "Window: pin (show on all workspaces)"
        case "splitratio":
            return "Window split ratio {}".format(params)
        case "togglefloating":
            return "Float/unfloat window"
        case "resizeactive":
            return "Resize window by {}".format(params)
        case "killactive":
            return "Close window"
        case "fullscreen":
            return "Toggle {}".format({
                "0": "fullscreen", "1": "maximization", "2": "fullscreen on Hyprland's side",
            }.get(params, "null"))
        case "fakefullscreen":
            return "Toggle fake fullscreen"
        case "workspace":
            if params == "+1":
                return "Workspace: focus right"
            elif params == "-1":
                return "Workspace: focus left"
            return "Focus workspace {}".format(params)
        case "movefocus":
            return "Window: move focus {}".format({
                "l": "left", "r": "right", "u": "up", "d": "down",
            }.get(params, "null"))
        case "swapwindow":
            return "Window: swap in {} direction".format({
                "l": "left", "r": "right", "u": "up", "d": "down",
            }.get(params, "null"))
        case "movetoworkspace":
            if params == "+1":
                return "Window: move to right workspace (non-silent)"
            elif params == "-1":
                return "Window: move to left workspace (non-silent)"
            return "Window: move to workspace {} (non-silent)".format(params)
        case "movetoworkspacesilent":
            if params == "+1":
                return "Window: move to right workspace"
            elif params == "-1":
                return "Window: move to right workspace"
            return "Window: move to workspace {}".format(params)
        case "togglespecialworkspace":
            return "Workspace: toggle special"
        case "exec":
            return "Execute: {}".format(params)
        case _:
            return ""


def split_mods(mods_str: str) -> List[str]:
    return [m.strip() for m in mods_str.split("+") if m.strip()]


def split_args(text: str) -> List[str]:
    """Divide argumentos de topo de uma chamada Lua, respeitando strings e parenteses."""
    args, depth, quote, cur = [], 0, None, ""
    for ch in text:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            cur += ch
        elif ch in "({[":
            depth += 1
            cur += ch
        elif ch in ")}]":
            depth -= 1
            cur += ch
        elif ch == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args


def unquote(text: str) -> str:
    text = text.strip()
    if len(text) >= 2 and text[0] in "\"'" and text[-1] == text[0]:
        return text[1:-1]
    return text


def make_keybind(keys: str, dispatcher: str, params: str, comment: str):
    if comment.startswith(HIDE_COMMENT):
        return None
    parts = split_mods(keys)
    key = parts[-1] if parts else ""
    mods = parts[:-1]
    if not comment:
        comment = autogenerate_comment(dispatcher, params)
    return KeyBinding(mods, key, dispatcher, params, comment)


def get_fake_keybind(line: str):
    """Linha `--/# MODS | KEY | descricao` so para exibir no cheatsheet."""
    fields = [f.strip() for f in line[len(COMMENT_BIND_PATTERN):].split("|", 2)]
    if len(fields) < 3:
        return None
    mods, key, comment = fields
    return make_keybind(mods + " + " + key if mods else key, "", "", comment)


def get_keybind_at_line(line: str):
    """Le `bind("MODS + KEY", dispatcher, "descricao"[, opts])` (bind/binde/bindm/bindrt)."""
    m = re.match(r"bind[a-z]*\((.*)\)\s*(--.*)?$", line.strip())
    if not m:
        return None
    args = split_args(m.group(1))
    if len(args) < 2:
        return None
    keys = args[0]
    if ".." in keys:
        # mainMod .. " + KEY"  ->  SUPER + KEY
        keys = "SUPER" + unquote(keys.split("..", 1)[1])
    else:
        keys = unquote(keys)
    comment = unquote(args[2]) if len(args) > 2 else ""
    dispatcher = args[1]
    return make_keybind(keys, dispatcher, "", comment)


def parse_keys(path: str) -> Dict:
    global content_lines
    global reading_line
    
    content_lines = read_content(path).splitlines()
    if not content_lines or content_lines[0] == "error":
        return {"children": [], "keybinds": [], "name": ""}
    
    root = Section([], [], "")
    current_column = None
    current_section = None
    
    for line in content_lines:
        stripped = line.strip()
        
        # Nova coluna (# >>>)
        if stripped.startswith(COLUMN_MARKER):
            column_name = stripped[len(COLUMN_MARKER):].strip()
            current_column = Section([], [], column_name)
            root["children"].append(current_column)
            current_section = None
        
        # Nova seção (# >>)
        elif stripped.startswith(SECTION_MARKER) and not stripped.startswith(COLUMN_MARKER):
            section_name = stripped[len(SECTION_MARKER):].strip()
            if current_column is not None:
                current_section = Section([], [], section_name)
                current_column["children"].append(current_section)
        
        # Keybind com comentário especial (#/#)
        elif stripped.startswith(COMMENT_BIND_PATTERN):
            keybind = get_fake_keybind(stripped)
            if keybind is not None:
                if current_section is not None:
                    current_section["keybinds"].append(keybind)
                elif current_column is not None:
                    current_column["keybinds"].append(keybind)
                else:
                    root["keybinds"].append(keybind)
        
        # Keybind normal
        elif stripped.startswith("bind"):
            keybind = get_keybind_at_line(stripped)
            if keybind is not None:
                if current_section is not None:
                    current_section["keybinds"].append(keybind)
                elif current_column is not None:
                    current_column["keybinds"].append(keybind)
                else:
                    root["keybinds"].append(keybind)
        
        reading_line += 1
    
    return root


if __name__ == "__main__":
    import json
    ParsedKeys = parse_keys(args.path)
    print(json.dumps(ParsedKeys))
