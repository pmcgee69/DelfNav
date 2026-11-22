"""DelphiLSP's processes in the capture: each start (with its parent and name), each crash
report (WerFault), each exit (with its code)."""
import csv, re, sys

with open(sys.argv[1], encoding='utf-8-sig', errors='replace', newline='') as f:
    for r in csv.DictReader(f):
        p, op, path, det = r['Process Name'], r['Operation'], r['Path'], r['Detail']
        if p not in ('DelphiLSP.exe', 'bds.exe', 'WerFault.exe'):
            continue
        keep = False
        if op == 'Process Start' and p == 'DelphiLSP.exe':
            det = re.sub(r', Current directory.*', '', det, flags=re.S)
            keep = True
        elif op == 'Process Create' and ('DelphiLSP' in path or 'WerFault' in path):
            det = 'creates ' + path.split('\\')[-1] + ' ' + re.sub(r'Command line: ', '', det)
            keep = True
        elif op == 'Process Exit' and p == 'DelphiLSP.exe':
            det = re.sub(r', User Time.*', '', det, flags=re.S)
            keep = True
        if keep:
            print(r['Time of Day'][:-6], p, r['PID'], op, det.replace('"', '')[:150])
