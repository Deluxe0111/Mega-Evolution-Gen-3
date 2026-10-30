#!/usr/bin/env python3
"""Extract all EBDX Mega assets with their source metadata (stdlib only).

All files are downloaded from a fixed upstream Git revision, not redistributed
inside this toolkit. No files in existing sprite collections are changed.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import csv
import hashlib
import json
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

REPO = 'ChromeValiant/Pokemon-Essentials-21-With-Unofficial-EBDX'
REVISION = '452d27cab271f7cf8f10d07e2236abb5c53b4899'
ROOT_URL = f'https://raw.githubusercontent.com/{REPO}/{REVISION}/'
AGENT = 'EBDX-Mega-Asset-Extractor/1.0 (source asset inventory)'
METADATA_FILES = [
    'PBS/pokemon_forms.txt',
    'PBS/pokemon_forms_Gen_9_Pack.txt',
    'PBS/pokemon_metrics.txt',
    'PBS/pokemon_metrics_Gen_9_Pack.txt',
    'PBS/items.txt',
    'PBS/items_Gen_9_Pack.txt',
    'README.md',
]
SPRITE_FILES = {
    'front': 'Graphics/Pokemon/Front',
    'back': 'Graphics/Pokemon/Back',
    'front_shiny': 'Graphics/Pokemon/Front shiny',
    'back_shiny': 'Graphics/Pokemon/Back shiny',
    'icon': 'Graphics/Pokemon/Icons',
    'icon_shiny': 'Graphics/Pokemon/Icons shiny',
}
UI_ASSETS = [
    'Graphics/EBDX/Pictures/mega_sym.png',
    'Graphics/EBDX/Pictures/UI/megaButton.png',
    'Graphics/EBDX/Pictures/UI/symMega.png',
    'Graphics/UI/Battle/cursor_mega.png',
    'Graphics/UI/Battle/icon_mega.png',
    'Graphics/Items/MEGARING.png',
    'Graphics/Items/MEGASHARD.png',
]


def request_bytes(rel: str, optional: bool = False) -> bytes | None:
    safe_url = ROOT_URL + urllib.parse.quote(rel, safe='/')
    req = urllib.request.Request(safe_url, headers={'User-Agent': AGENT})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=35) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            if exc.code == 404 and optional:
                return None
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise
        except (urllib.error.URLError, TimeoutError):
            if attempt == 3:
                raise
        time.sleep(1.5 * (attempt + 1))
    raise AssertionError('retry exhausted')


def parse_pbs(text: str, label: str) -> list[dict]:
    """Read official Pokémon Essentials PBS sections, preserving extra fields."""
    out, current = [], None
    for line in text.replace('\ufeff', '').splitlines():
        section = re.fullmatch(r'\s*\[([^\]]+)\]\s*', line)
        if section:
            if current:
                out.append(current)
            head = section.group(1).split(',')
            current = {'pbs_key': section.group(1), 'source': label,
                       'species': head[0].strip(),
                       'form': int(head[1].strip()) if len(head) > 1 and head[1].strip().isdigit() else 0}
            continue
        if current and '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            current[key.strip()] = value.strip()
    if current:
        out.append(current)
    return out


def slug_for(entry: dict) -> str:
    name = entry.get('FormName') or ''
    if not name.lower().startswith('mega '):
        return f"mega_{entry['species'].lower()}_form_{entry['form']}"
    rest = name[5:].lower()
    rest = re.sub(r'\s*\((curly|droopy|stretchy)\s+form\)', r' \1', rest)
    return re.sub(r'_+', '_', re.sub(r'[^a-z0-9]+', '_', 'mega_' + rest)).strip('_')


def load_metadata(output: Path) -> dict[str, str]:
    saved = {}
    for remote in METADATA_FILES:
        print(f'  Metadata: {remote}', flush=True)
        data = request_bytes(remote)
        if data is None:
            raise ValueError(f'Missing required source metadata: {remote}')
        target = output / 'source_metadata' / remote
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        saved[remote] = data.decode('utf-8-sig', errors='replace')
    return saved


def create_roster(raw: dict[str, str]) -> list[dict]:
    entries = (parse_pbs(raw['PBS/pokemon_forms.txt'], 'base') +
               parse_pbs(raw['PBS/pokemon_forms_Gen_9_Pack.txt'], 'gen9'))
    eligible = [e for e in entries if re.search(r'\bmega\b', e.get('FormName', ''), re.I)
                or e.get('MegaStone') or e.get('MegaMove')]
    by_key = {e['pbs_key']: e for e in entries}
    output, slugs = [], set()
    for e in eligible:
        e = e.copy()
        if not e.get('FormName'):
            original = by_key.get(f"{e['species']},{e.get('UnmegaForm', '0')}", {})
            hint = original.get('FormName', '').strip()
            e['display_name'] = f"Mega {e['species'].title()} ({hint or 'alternate variant ' + str(e['form'])})"
        else:
            e['display_name'] = e['FormName']
        e['slug'] = slug_for(e)
        if e['slug'] in slugs:
            raise ValueError(f'Duplicate slug: {e["slug"]}')
        slugs.add(e['slug'])
        base_form = int(e.get('UnmegaForm', 0))
        e['source_filename'] = f"{e['species']}_{e['form']}.png"
        e['base_source_filename'] = (f"{e['species']}_{base_form}.png" if base_form else f"{e['species']}.png")
        e['base_form'] = base_form
        output.append(e)
    if not eligible:
        raise ValueError('No Mega forms found; source format may have changed')
    return output


def write_csv(path: Path, rows: list[dict], fields: list[str]):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=fields, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)


def plan_assets(roster: list[dict], base: bool) -> list[dict]:
    plan = []
    seen = set()

    def add(group, slug, kind, source, target, required=True):
        if target in seen:
            return
        seen.add(target)
        plan.append({'group': group, 'mega': slug, 'kind': kind, 'remote': source,
                     'target': target, 'required': required})

    for e in roster:
        slug, stem = e['slug'], e['source_filename']
        for kind, directory in SPRITE_FILES.items():
            add('mega_art', slug, kind, f'{directory}/{stem}',
                f'megas/{slug}/{kind}.png')
        if base:
            for kind, directory in SPRITE_FILES.items():
                # Shared normal/reversion forms need not be downloaded repeatedly.
                add('base_art', slug, kind, f"{directory}/{e['base_source_filename']}",
                    f"base_forms/{e['species'].lower()}_{e['base_form']}/{kind}.png")
        add('cry', slug, 'mega_cry', f"Audio/SE/Cries/{e['species']}_{e['form']}.ogg",
            f'megas/{slug}/cry.ogg', required=False)
    for e in roster:
        stone = e.get('MegaStone', '')
        if stone:
            add('mega_stones', e['slug'], 'stone_icon', f'Graphics/Items/{stone}.png',
                f'mega_stones/{stone}.png')
    for source in UI_ASSETS:
        add('ui_reference', '', 'ui_asset', source, f"ui_reference/{source}")
    return plan


def fetch_one(output: Path, row: dict) -> dict:
    result = dict(row)
    path = output / row['target']
    try:
        if path.exists() and path.stat().st_size > 0:
            content = path.read_bytes()
            result['status'] = 'already_present'
        else:
            content = request_bytes(row['remote'], optional=not row['required'])
            if content is None:
                result.update(status='absent_upstream', bytes=0, sha256='')
                return result
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_suffix(path.suffix + '.part')
            # Validate downloaded payload before making it the final asset.
            if row['target'].endswith('.png') and content[:8] != b'\x89PNG\r\n\x1a\n':
                raise ValueError('Source is not a PNG file')
            if row['target'].endswith('.ogg') and content[:4] != b'OggS':
                raise ValueError('Source is not an OGG file')
            temporary.write_bytes(content)
            temporary.replace(path)
            result['status'] = 'downloaded' 
        result['bytes'] = len(content)
        result['sha256'] = hashlib.sha256(content).hexdigest()
        if row['target'].endswith('.png') and content[:8] != b'\x89PNG\r\n\x1a\n':
            raise ValueError('File does not have PNG signature')
        if row['target'].endswith('.ogg') and content[:4] != b'OggS':
            raise ValueError('File does not have OGG signature')
    except Exception as exc:
        result['status'] = 'failed'
        result['error'] = str(exc)
        if path.exists() and path.stat().st_size == 0:
            path.unlink()
    return result


def main() -> int:
    p = argparse.ArgumentParser(description='Download EBDX Mega forms and related assets (copy only)')
    p.add_argument('--out', type=Path, default=Path('EBDX_Mega_Assets'),
                   help='New folder to create; existing files are never overwritten')
    p.add_argument('--preview', action='store_true', help='Only download source text and produce plans')
    p.add_argument('--include-base', action='store_true',
                   help='Also fetch each original/reversion form (six images per base form)')
    p.add_argument('--workers', type=int, default=4, help='Concurrent asset downloads (1..8)')
    args = p.parse_args()
    if not 1 <= args.workers <= 8:
        p.error('--workers must be between 1 and 8')
    output = args.out.resolve()
    output.mkdir(parents=True, exist_ok=True)
    print(f'EBDX Mega asset source: {REPO} @ {REVISION}')
    print(f'Output: {output}')
    print('Downloading original form definitions, item data, metrics and upstream credits...')
    try:
        raw = load_metadata(output)
        roster = create_roster(raw)
    except Exception as exc:
        print('Cannot read metadata:', exc, file=sys.stderr)
        return 2
    plan = plan_assets(roster, args.include_base)
    roster_fields = ['slug', 'display_name', 'species', 'form', 'base_form',
                     'source_filename', 'base_source_filename', 'FormName',
                     'MegaStone', 'MegaMove', 'UnmegaForm', 'BaseStats',
                     'Types', 'Abilities', 'HiddenAbilities', 'source', 'pbs_key']
    write_csv(output / 'mega_roster.csv', roster, roster_fields)
    (output / 'mega_forms.json').write_text(json.dumps({
        'source_repo': REPO, 'pinned_revision': REVISION,
        'forms': roster}, indent=2, ensure_ascii=False), encoding='utf-8')
    fields = ['group', 'mega', 'kind', 'remote', 'target', 'required', 'status', 'bytes', 'sha256', 'error']
    write_csv(output / 'asset_plan.csv', plan, fields)
    (output / 'SOURCE_AND_CREDITS.txt').write_text(
        'Source: https://github.com/' + REPO + '\nPinned revision: ' + REVISION +
        '\n\nThe downloaded source_metadata/README.md contains original sprite/art contributor credits.\n'
        'These assets are third-party material. Public visibility is not a redistribution licence.\n'
        'Before packing assets into a publicly distributed Gen1Recomp mod, verify permissions\n'
        'for the specific art and retain original contributor attribution.\n\n'
        'PNG files here are the original EBDX image sheets, NOT pre-converted GIF animations.\n'
        'PBS data is reference metadata, NOT directly compatible Gen1Recomp battle mechanics.\n',
        encoding='utf-8')
    print(f'Roster: {len(roster)} Mega-form variants, {len(set(e["species"] for e in roster))} base species')
    print('Plan by group:', ', '.join(f'{k}={v}' for k, v in sorted(Counter(x['group'] for x in plan).items())))
    if args.preview:
        print('Preview complete: no image, cry or UI assets downloaded.')
        return 0
    print(f'Downloading {len(plan)} planned assets; existing downloads will be reused...')
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(fetch_one, output, row) for row in plan]
        for i, future in enumerate(concurrent.futures.as_completed(futures), 1):
            r = future.result()
            results.append(r)
            if r['status'] in ('failed', 'absent_upstream'):
                print(f"  {r['status']}: {r['remote']} {r.get('error', '')}")
            if i % 50 == 0 or i == len(plan):
                print(f'  {i} / {len(plan)} processed', flush=True)
    results.sort(key=lambda x: (x['group'], x['target']))
    write_csv(output / 'download_results.csv', results, fields)
    missing = [r for r in results if r['status'] in ('failed', 'absent_upstream')]
    write_csv(output / 'missing_assets.csv', missing, fields)
    by_slug = defaultdict(list)
    for row in results:
        if row['group'] == 'mega_art':
            by_slug[row['mega']].append(row)
    summary = []
    for e in roster:
        ours = by_slug[e['slug']]
        summary.append({'mega': e['slug'], 'display_name': e['display_name'],
                        'art_count': sum(x['status'] not in ('failed', 'absent_upstream') for x in ours),
                        'complete': len(ours) == 6 and all(x['status'] not in ('failed', 'absent_upstream') for x in ours)})
    write_csv(output / 'mega_coverage.csv', summary,
              ['mega', 'display_name', 'art_count', 'complete'])
    counts = Counter(x['status'] for x in results)
    print('Finished:', dict(counts))
    print(f'Full-art Mega forms: {sum(e["complete"] for e in summary)}/{len(summary)}')
    print('Reports: asset_plan.csv, mega_roster.csv, mega_coverage.csv,')
    print('         download_results.csv, missing_assets.csv')
    return 1 if any(r['required'] for r in missing) else 0


if __name__ == '__main__':
    sys.exit(main())
