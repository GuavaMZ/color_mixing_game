import json

def summarize():
    try:
        with open('assets/levels.json', 'rb') as f:
            data = f.read().decode('utf-16')
            levels = json.loads(data)['levels']
            for l in levels[:55]:
                recipe = l['recipe']
                summary = []
                for k, v in recipe.items():
                    if v > 0:
                        summary.append(f"{k}: {v}")
                print(f"Level {l['id']}: {', '.join(summary)}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    summarize()
