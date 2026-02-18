#!/usr/bin/env python3
import argparse
import re
import os
from typing import Dict, List


COLUMN_MARKER = "# >>>"  # Títulos grandes (colunas)
SECTION_MARKER = "# >>"   # Subtítulos (seções)
HIDE_COMMENT = "[hidden]"
MOD_SEPARATORS = ['+', ' ']
COMMENT_BIND_PATTERN = "#/#"


parser = argparse.ArgumentParser(description='Hyprland keybind reader')
parser.add_argument('--path', type=str, default="$HOME/.config/hypr/hyprland.conf", help='path to keybind file')
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


def get_keybind_at_line(line_number, line_start=0):
    global content_lines
    line = content_lines[line_number]
    _, keys = line.split("=", 1)
    keys, *comment = keys.split("#", 1)

    mods, key, dispatcher, *params = list(map(str.strip, keys.split(",", 4)))
    params = "".join(map(str.strip, params))

    comment = list(map(str.strip, comment))
    if comment:
        comment = comment[0]
        if comment.startswith(HIDE_COMMENT):
            return None
    else:
        comment = autogenerate_comment(dispatcher, params)

    if mods:
        modstring = mods + MOD_SEPARATORS[0]
        mods = []
        p = 0
        for index, char in enumerate(modstring):
            if char in MOD_SEPARATORS:
                if index - p > 1:
                    mods.append(modstring[p:index])
                p = index + 1
    else:
        mods = []

    return KeyBinding(mods, key, dispatcher, params, comment)


def parse_keys(path: str) -> Dict:
    global content_lines
    global reading_line
    
    content_lines = read_content(path).splitlines()
    if content_lines[0] == "error":
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
            keybind = get_keybind_at_line(reading_line, line_start=len(COMMENT_BIND_PATTERN))
            if keybind is not None:
                if current_section is not None:
                    current_section["keybinds"].append(keybind)
                elif current_column is not None:
                    current_column["keybinds"].append(keybind)
                else:
                    root["keybinds"].append(keybind)
        
        # Keybind normal
        elif stripped.startswith("bind"):
            reading_line_temp = content_lines.index(line)
            keybind = get_keybind_at_line(reading_line_temp)
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
