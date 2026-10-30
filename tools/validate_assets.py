#!/usr/bin/env python3
"""Audit imported EBDX Mega artwork, read-only. Python 3 standard library."""
import argparse
import csv
import json
from pathlib import Path

KINDS = ('front', 'back', 'front_shiny', 'back_shiny', 'icon', 'icon_shiny')
PNG = b'\x89PNG\r\n\x1a\n'

def audit(root: Path):
    meta = root / 'mega_forms.json'
    if not meta.is_file():
        return None, []
    forms = json.loads(meta.read_text(encoding='utf8')).get('forms', [])
    report = []
    for form in forms:
        slug = form['slug']
        for kind in KINDS:
            path = root/'megas'/slug/(kind+'.png')
            if not path.exists(): status='missing'
            elif path.read_bytes()[:8] != PNG: status='invalid_png'
            else: status='ok'
            report.append({'mega':slug,'kind':kind,'status':status,'path':str(path)})
        stone = form.get('MegaStone')
        if stone:
            path=root/'mega_stones'/(stone+'.png')
            status='missing' if not path.exists() else ('ok' if path.read_bytes()[:8] == PNG else 'invalid_png')
            report.append({'mega':slug,'kind':'stone','status':status,'path':str(path)})
        cry=root/'megas'/slug/'cry.ogg'
        if cry.exists():
            status='ok' if cry.read_bytes()[:4] == b'OggS' else 'invalid_ogg'
        else:
            status='optional_absent'
        report.append({'mega':slug,'kind':'cry','status':status,'path':str(cry)})
    return forms, report

def main():
    p=argparse.ArgumentParser(description='Audit the 6 sprite variants for each EBDX Mega')
    p.add_argument('--root',type=Path,default=Path('assets/source/ebdx'))
    p.add_argument('--strict',action='store_true',help='exit nonzero if required assets absent')
    args=p.parse_args()
    root=args.root.resolve()
    forms, report=audit(root)
    if forms is None:
        print('No mega_forms.json found at', root)
        print('Run 1_IMPORT_EBDX_ASSETS.bat, or copy an existing EBDX_Mega_Assets folder here.')
        return 2 if args.strict else 0
    target=root/'repo_asset_audit.csv'
    with target.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['mega','kind','status','path'])
        w.writeheader(); w.writerows(report)
    complete=sum(all(any(r['mega']==form['slug'] and r['kind']==kind and r['status']=='ok' for r in report) for kind in KINDS) for form in forms)
    missing=[r for r in report if r['status'] not in ('ok','optional_absent')]
    print(f'Forms with complete six-variant art: {complete}/{len(forms)}')
    print(f'Missing or invalid required asset references: {len(missing)}')
    print(f'CSV report: {target}')
    for r in missing[:25]: print(' ',r['mega'],r['kind'],r['status'])
    if len(missing)>25: print(f'  ... and {len(missing)-25} more in CSV')
    return 1 if (args.strict and missing) else 0

if __name__=='__main__':
    raise SystemExit(main())
