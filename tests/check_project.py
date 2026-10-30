import json
from pathlib import Path
r=Path(__file__).resolve().parent.parent
m=json.loads((r/'manifest.json').read_text(encoding='utf8'))
assert m['id']=='mega-evolution-gen3'
assert m['api']==2 and m['entry']=='main.lua'
assert 'gen3' in m['games']
assert (r/m['entry']).exists()
assert 'mega-evolution' in m['id']
assert 'Aronousqui' in (r/'CREDITS.md').read_text(encoding='utf8')
assert 'mangalos810' in (r/'CREDITS.md').read_text(encoding='utf8')
print('Repository metadata and artwork credits: PASS')
