import json
import math

def rgb_to_hsl(r, g, b):
    # Normalize with 0.1 delta for black/white influence? 
    # Actually just pure RGB logic.
    r /= 255.0
    g /= 255.0
    b /= 255.0
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    l = (max_c + min_c) / 2.0
    
    if max_c == min_c:
        h = s = 0.0
    else:
        d = max_c - min_c
        s = d / (2.0 - max_c - min_c) if l > 0.5 else d / (max_c + min_c)
        if max_c == r:
            h = (g - b) / d + (6.0 if g < b else 0.0)
        elif max_c == g:
            h = (b - r) / d + 2.0
        else:
            h = (r - g) / d + 4.0
        h /= 6.0
    return h * 360.0, s * 100.0, l * 100.0

def get_name(h, s, l):
    if l < 15: return "Deep Obsidian"
    if l > 85: 
        if s < 10: return "Spectral Ivory"
        return "Pale Phosphor"
    if s < 15:
        if l < 40: return "Shadow Gray"
        if l < 60: return "Nebula Gray"
        return "Stardust Silver"
        
    # Standard Hues
    if h < 15 or h >= 345: return "Crimson Ion" if l < 40 else ("Rose Plasma" if l > 60 else "Scarlet Matter")
    if h < 45: return "Amber Isotope"
    if h < 75: return "Solar Flare" if s > 70 else "Citrine Core"
    if h < 105: return "Chartreuse Flux"
    if h < 165: return "Emerald Matrix" if l < 50 else "Lime Aurora"
    if h < 195: return "Cyan Vapor"
    if h < 225: return "Azure Wave" if l < 50 else "Sky Pulsar"
    if h < 255: return "Indigo Fractal"
    if h < 285: return "Violet Singularity"
    if h < 315: return "Magenta Fusion"
    if h < 345: return "Neon Fuchsia"
    return "Unknown Compound"

def create_mapping():
    try:
        with open('assets/levels.json', 'rb') as f:
            data = f.read().decode('utf-16')
            levels = json.loads(data)['levels']
            
            mapping = {}
            for l in levels[:50]:
                recipe = l['recipe']
                # Simplified mixing logic to match ColorLogic.dart
                r = recipe.get('red', 0)
                g = recipe.get('green', 0)
                b = recipe.get('blue', 0)
                w = recipe.get('white', 0)
                k = recipe.get('black', 0)
                
                total = r + g + b + w + k
                if total == 0:
                    mapping[l['id']] = "Vacuum Void"
                    continue
                
                # Basic mixing (simplified)
                # Weights for RGB
                rw = (r + w) * 255 / total
                gw = (g + w) * 255 / total
                bw = (b + w) * 255 / total
                
                # Black influence
                k_factor = 1.0 - (k / total)
                rw *= k_factor
                gw *= k_factor
                bw *= k_factor
                
                h, s, sl = rgb_to_hsl(rw, gw, bw)
                mapping[l['id']] = get_name(h, s, sl)
                
            for i in range(1, 51):
                name = mapping.get(i, f"Specimen {i}")
                print(f"    {i}: \"{name}\",")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    create_mapping()
