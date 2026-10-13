import subprocess,time,os,sys,glob,json,statistics as st
ROOT='/tmp/claude-0/all'
VM=os.environ.get('VMBIN','/home/claude/adesutherland/build/bin')
TAG=os.environ.get('TAG','stock')
N=int(os.environ.get('N','3'))
only=sys.argv[1:]
env=dict(os.environ,PATH=VM+':'+os.environ['PATH'],CREXX_BIN=VM,CREXX=VM+'/crexx',CREXX_VM=VM+'/crexx',TMPDIR='/tmp/claude-0/all/tmp')
os.makedirs(env['TMPDIR'],exist_ok=True)
def skipset(p):
    try: return set(x.strip() for x in open(p) if x.strip() and not x.startswith('#'))
    except: return set()
L={
 'plm':dict(g='PLM/tests/*.plm',cmd=lambda f:[ROOT+'/PLM/plmc',os.path.basename(f)],cwd='PLM/tests'),
 'pascal':dict(g='pascal/tests/*.pas',cmd=lambda f:[ROOT+'/pascal/pasc',f],cwd='pascal/tests'),
 'lisp':dict(g='lisp/tests/*.lisp',cmd=lambda f:[ROOT+'/lisp/lisp',f],cwd='lisp/tests'),
 'xbase':dict(g='xbase/tests/*.prg',cmd=lambda f:[ROOT+'/xbase/xbase',f],cwd=None),
 'smalltalk':dict(g='smalltalk/tests/*.st',cmd=lambda f:[ROOT+'/smalltalk/smalltalk']+(open(f[:-3]+'.flags').read().split() if os.path.exists(f[:-3]+'.flags') else [])+[f],cwd='smalltalk/tests'),
 'python':dict(g='python/tests/*.py',cmd=lambda f:[ROOT+'/python/crexx/py',f],cwd='python/tests',skip=skipset(ROOT+'/python/tests/crexx_skip.txt'),n=2),
}
res=[]
for lang,c in L.items():
    if only and lang not in only: continue
    for f in sorted(glob.glob(ROOT+'/'+c['g'])):
        name=os.path.basename(f).rsplit('.',1)[0]
        if name in c.get('skip',()): continue
        inp=f.rsplit('.',1)[0]+'.in'; inp=inp if os.path.exists(inp) else '/dev/null'
        exp=open(f.rsplit('.',1)[0]+'.out',errors='replace').read().rstrip('\n')
        xs=[];ok=True
        for _ in range(c.get('n',N)):
            import tempfile;wd=tempfile.mkdtemp(dir=env['TMPDIR'])
            a=time.perf_counter()
            r=subprocess.run(c['cmd'](f),stdin=open(inp),capture_output=True,env=env,cwd=(ROOT+'/'+c['cwd']) if c['cwd'] and lang!='xbase' else wd,timeout=600)
            xs.append(time.perf_counter()-a)
            out=(r.stdout+r.stderr).decode(errors='replace').rstrip('\n')
            ok=ok and out==exp
        res.append(dict(lang=lang,name=name,min=min(xs),med=st.median(xs),ok=ok))
        print(lang,name,'%.3f'%min(xs),'ok' if ok else 'DIFF',flush=True)
json.dump(res,open(f'{ROOT}/res_{TAG}.json' if not only else f'{ROOT}/res_{TAG}_{"_".join(only)}.json','w'),indent=1)
