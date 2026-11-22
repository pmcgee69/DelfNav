"""Process Monitor's CSV: DelphiLSP's reads of .lsif files. Per file: first and last read,
bytes read, which process and threads; then whether files' read spans overlap.
usage: lsif.py <lsp.csv>"""
import collections, csv, re, sys

rows = []
with open(sys.argv[1], encoding='utf-8-sig', errors='replace', newline='') as f:
    r = csv.DictReader(f)
    cols = r.fieldnames
    for row in r:
        if 'lsif' not in row.get('Path', '').lower():
            continue
        rows.append(row)
print('columns:', cols)
print(len(rows), 'events on .lsif files')


def secs(t):
    # "2:55:01.1234567 PM"
    m = re.match(r'(\d+):(\d+):(\d+)\.(\d+)\s*(AM|PM)?', t.strip())
    h, mi, s, frac, ap = m.groups()
    h = int(h) % 12 + (12 if ap == 'PM' else 0)
    return h * 3600 + int(mi) * 60 + int(s) + float('0.' + frac)


ops = collections.Counter((r['Process Name'], r['Operation']) for r in rows)
for k, v in ops.most_common(12):
    print(f'{v:8}  {k}')

per = collections.defaultdict(lambda: {'first': None, 'last': None, 'bytes': 0, 'reads': 0,
                                       'pids': set(), 'tids': set(), 'opened': None})
for r in rows:
    name = r['Path'].replace('\\', '/').rsplit('/', 1)[-1]
    t = secs(r['Time of Day'])
    p = per[(r['PID'], name)]
    if r['Operation'] == 'CreateFile' and p['opened'] is None:
        p['opened'] = t
    if r['Operation'] != 'ReadFile':
        continue
    p['reads'] += 1
    p['first'] = t if p['first'] is None else min(p['first'], t)
    p['last'] = t if p['last'] is None else max(p['last'], t)
    m = re.search(r'Length: ([\d,]+)', r['Detail'])
    if m:
        p['bytes'] += int(m.group(1).replace(',', ''))
    p['tids'].add(r.get('TID', '?'))

pnames = {r['PID']: r['Process Name'] for r in rows}
read = {k: v for k, v in per.items() if v['reads']}
if not read:
    sys.exit('no reads')
t0 = min(v['opened'] or v['first'] for v in read.values())
print(f"\n{'pid':>6} {'file':24} {'opened':>7} {'first':>7} {'last':>7} {'span':>6} {'MB':>7} {'reads':>7} threads")
for (pid, name), v in sorted(read.items(), key=lambda kv: kv[1]['first']):
    print(f"{pid:>6} {name:24} {((v['opened'] or v['first']) - t0):7.2f} {v['first'] - t0:7.2f} "
          f"{v['last'] - t0:7.2f} {v['last'] - v['first']:6.2f} {v['bytes'] / 1e6:7.1f} {v['reads']:7} "
          f"{len(v['tids'])} ({','.join(sorted(v['tids']))[:40]})  {pnames.get(pid, '')}")
# how many files were being read at once, in 0.1 s steps
end = max(v['last'] for v in read.values())
print('\nfiles mid-read, every 0.25 s:')
t = t0
line = []
while t <= end + 0.25:
    n = sum(1 for v in read.values() if v['first'] <= t <= v['last'])
    line.append(f'{t - t0:.2f}:{n}')
    t += 0.25
print(' '.join(line))
