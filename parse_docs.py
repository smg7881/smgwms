import json
import re

with open('c:/Users/smg/.gemini/antigravity/brain/63798944-e91a-432b-931b-aab2999b5fc4/.system_generated/steps/38/output.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

sources = data['notebook'][0][1]

an13 = {}
ds02 = {}

for src in sources:
    if isinstance(src[0], list):
        src_id = src[0][0]
        title = src[1]
    else:
        continue

    if 'AN13' in title:
        parts = title.split('_')
        if len(parts) >= 2:
            name = ''.join(parts[1:-1]).replace('팝업', '')
            an13[name] = src_id
    elif 'DS02' in title:
        part = title.split('-')[-1]
        name = part.replace('.pdf', '').replace('_', '').replace('팝업', '')
        ds02[name] = src_id

matches = []
for name in an13:
    if name in ds02 and name not in ['거래처관리', '작업장관리', '시스템설정관리']:
        matches.append((name, an13[name], ds02[name]))

with open('c:/Users/smg/.gemini/antigravity/docs_list.json', 'w', encoding='utf-8') as f:
    json.dump(matches, f, ensure_ascii=False, indent=2)
