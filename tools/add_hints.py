import json

file_path = r"d:\Work\color_mixing_deductive\assets\levels.json"

with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

def get_hint(r, g, b, w, k):
    if w > 0 and r == 0 and g == 0 and b == 0 and k == 0: return "hint_pure_white"
    if k > 0 and r == 0 and g == 0 and b == 0 and w == 0: return "hint_pure_black"
    if w > 0 and w >= r and w >= g and w >= b: return "hint_needs_white"
    if k > 0 and k >= r and k >= g and k >= b: return "hint_needs_black"
    if r > 0 and g == 0 and b == 0: return "hint_pure_red"
    if g > 0 and r == 0 and b == 0: return "hint_pure_green"
    if b > 0 and r == 0 and g == 0: return "hint_pure_blue"
    if r == g and r > 0 and b == 0: return "hint_mix_rg"
    if r == b and r > 0 and g == 0: return "hint_mix_rb"
    if g == b and g > 0 and r == 0: return "hint_mix_gb"
    if r > g and r > b:
        if g > 0 and b > 0: return "hint_mostly_red"
        if g > 0: return "hint_mix_rg"
        return "hint_mix_rb"
    if g > r and g > b:
        if r > 0 and b > 0: return "hint_mostly_green"
        if r > 0: return "hint_mix_rg"
        return "hint_mix_gb"
    if b > r and b > g:
        if r > 0 and g > 0: return "hint_mostly_blue"
        if r > 0: return "hint_mix_rb"
        return "hint_mix_gb"
    if r == g and g == b and r > 0: return "hint_balance_all"
    return "hint_observe"

for level in data:
    r = level.get("recipe", {}).get("R", 0)
    g = level.get("recipe", {}).get("G", 0)
    b = level.get("recipe", {}).get("B", 0)
    w = level.get("recipe", {}).get("W", 0)
    k = level.get("recipe", {}).get("K", 0)
    level["hint"] = get_hint(r, g, b, w, k)

with open(file_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print("Hints added successfully.")
