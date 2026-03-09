import json
import itertools
import math
from functools import reduce

COLORS = ['R', 'G', 'B', 'W', 'K']

levels = []
level_id = 1

def gcd_list(numbers):
    return reduce(math.gcd, numbers)

def add_level(phase, recipe):
    global level_id
    num_drops = sum(recipe.values())
    time_limit = 15 + (len(recipe) * 5) + ((num_drops - len(recipe)) * 2)
    time_limit = min(60, time_limit)
    
    # maxDrops provides some buffer over the minimum required recipe
    max_drops = num_drops + 5
    
    level = {
        "id": level_id,
        "phase": phase,
        "targetColor": {},
        "recipe": recipe,
        "baseScore": num_drops * 100,
        "timeLimit": time_limit,
        "maxDrops": max_drops
    }
    levels.append(level)
    level_id += 1

def generate_compositions(n, k):
    if k == 1:
        yield (n,)
        return
    for i in range(1, n - k + 2):
        for comp in generate_compositions(n - i, k - 1):
            yield (i,) + comp

# Store generated recipes as a set of unique tuples to prevent mathematically identical ratios
# A mathematically identical ratio is one where all components can be divided by a common GCD > 1.
# So if we only pick the ones where GCD == 1, we get unique color proportions.

for phase in range(1, 6):
    combos = list(itertools.combinations(COLORS, phase))
    
    # Phase 1 exactly 1 drop (5 levels)
    if phase == 1:
        for c in COLORS:
            add_level(1, {c: 1})
        continue

    # For other phases, we increase drops up to a high limit to get plenty of variations,
    # but filter out any composition where GCD > 1 to ensure unique target colors.
    max_drops_for_phase = 10
    if phase == 2:
        max_drops_for_phase = 14
    elif phase == 3:
        max_drops_for_phase = 10
    elif phase == 4:
        max_drops_for_phase = 8
    elif phase == 5:
        max_drops_for_phase = 8

    # We collect them and then sort them by total drops so easier levels come first
    phase_levels = []
    
    for num_drops in range(phase, max_drops_for_phase + 1):
        compositions = list(generate_compositions(num_drops, phase))
        for comp in compositions:
            if gcd_list(comp) > 1:
                # This color ratio is a scaled up version of a simpler one. Skip it to ensure unique target colors.
                continue
            
            for c_combo in combos:
                recipe = {c_combo[i]: comp[i] for i in range(phase)}
                phase_levels.append(recipe)
                
    # Now sort by number of total drops (simplest first)
    phase_levels.sort(key=lambda r: sum(r.values()))
    
    for recipe in phase_levels:
        add_level(phase, recipe)

print(f"Total levels generated: {len(levels)}")
from collections import Counter
phase_counts = Counter(l['phase'] for l in levels)
for p in range(1, 6):
    print(f"Phase {p}: {phase_counts[p]} levels")

with open('assets/levels.json', 'w') as f:
    json.dump(levels, f, indent=2)

print("Saved to assets/levels.json")
