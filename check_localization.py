
import re

def analyze_strings(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find constants: static const String redColor = "red_color";
    # constants[i] = (identifier, value)
    constants = re.findall(r'static const String (\w+) = ["\'](\w+)["\'];', content)
    ids = [c[0] for c in constants]
    id_to_value = {c[0]: c[1] for c in constants}

    results = []
    results.append(f"Total defined constants: {len(ids)}")
    
    map_names = ['En', 'Ar', 'Es', 'Fr']
    for name in map_names:
        start_match = re.search(fr'static const Map<String, dynamic> {name} = \{{', content)
        if not start_match:
            results.append(f"\nMap {name} NOT FOUND")
            continue
        
        start_idx = start_match.end()
        brace_count = 1
        current_idx = start_idx
        while brace_count > 0 and current_idx < len(content):
            if content[current_idx] == '{':
                brace_count += 1
            elif content[current_idx] == '}':
                brace_count -= 1
            current_idx += 1
        
        map_content = content[start_idx:current_idx-1]
        # Find keys in map (identifiers followed by :)
        map_keys = re.findall(r'(\w+):', map_content)
        map_keys_set = set(map_keys)
        
        missing = [i for i in ids if i not in map_keys_set]
        extra = [m for m in map_keys if m not in set(ids)]
        
        results.append(f"\nMap: {name}")
        results.append(f"Total entries in map: {len(map_keys)}")
        
        if missing:
            results.append(f"Missing identifiers: {len(missing)}")
            for m in missing:
                results.append(f"  - {m} (Value: {id_to_value[m]})")
        else:
            results.append("No missing entries!")
            
        if extra:
            results.append(f"Extra entries (not constants): {len(extra)}")
            for e in extra:
                results.append(f"  - {e}")

    with open('localization_report.txt', 'w', encoding='utf-8') as f:
        f.write("\n".join(results))

if __name__ == "__main__":
    analyze_strings(r'd:\Work\color_mixing_deductive\lib\helpers\string_manager.dart')
