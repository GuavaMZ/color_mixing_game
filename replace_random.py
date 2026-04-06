import os
import re

lib_dir = r"d:\Work\color_mixing_deductive\lib"
import_statement = "import 'package:color_mixing_deductive/helpers/global_variables.dart';\n"
pattern = re.compile(r"([^\w\.])Random\(\)")

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart"):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content, count = pattern.subn(r"\1GlobalConstants.sharedRandom", content)

            if count > 0:
                print(f"Replaced {count} instances in {filepath}")
                if import_statement.strip() not in new_content:
                    # add import after the last import statement or at top
                    lines = new_content.split('\n')
                    last_import_idx = -1
                    for i, line in enumerate(lines):
                        if line.startswith('import '):
                            last_import_idx = i
                    
                    if last_import_idx != -1:
                        lines.insert(last_import_idx + 1, import_statement.strip())
                    else:
                        lines.insert(0, import_statement.strip())
                    
                    new_content = '\n'.join(lines)

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
