import subprocess, time, os, sys, statistics, json, resource, hashlib, glob
B='/home/claude/adesutherland/build/bin/rxvm'
R='/tmp/claude-0/bench'
mods={'base':{},'cre':{'logo':['crecond','crenum','cretext'],'basic':['crecond','creio','crenum','cretext'],'snobol':['crecond','creio','crenum','cretext']}}
def cmd(var,lang,args):
    d=f'{R}/{var}/{lang}'
    return [B,f'{d}/{lang}']+[f'{d}/{m}' for m in mods[var].get(lang,[])]+['-a']+args
def run(var,lang,args,cwd,stdin,outfile=None):
    if outfile and os.path.exists(outfile): os.remove(outfile)
    inp=open(stdin,'rb') if stdin else subprocess.DEVNULL
    r0=resource.getrusage(resource.RUSAGE_CHILDREN)
    t=time.perf_counter()
    p=subprocess.run(cmd(var,lang,args),cwd=cwd,stdin=inp,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
    el=time.perf_counter()-t
    r1=resource.getrusage(resource.RUSAGE_CHILDREN)
    cpu=(r1.ru_utime-r0.ru_utime)+(r1.ru_stime-r0.ru_stime)
    out=p.stdout
    if outfile and os.path.exists(outfile): out+=open(outfile,'rb').read()
    return el,cpu,out.replace(f'{R}/{"base"}'.encode(),b'X').replace(f'{R}/cre'.encode(),b'X'),p.returncode
W=[]
def add(lang,name,args,cwd,stdin=None,outfile=None): W.append((lang,name,args,cwd,stdin,outfile))
T='/home/claude/basic/tests'
for f in sorted(glob.glob(T+'/*.bas')):
    n=os.path.basename(f)[:-4]; fl=open(f'{T}/{n}.flags').read().split() if os.path.exists(f'{T}/{n}.flags') else []
    add('basic','tests/'+n,fl+[f],T,f'{T}/{n}.in' if os.path.exists(f'{T}/{n}.in') else None)
for n in ('out','parse'): add('basic','synthetic/'+n,[f'{R}/work/{n}.bas'],R+'/work')
T='/home/claude/snobol/tests'
for f in sorted(glob.glob(T+'/*.sno')):
    n=os.path.basename(f)[:-4]; fl=open(f'{T}/{n}.flags').read().split() if os.path.exists(f'{T}/{n}.flags') else []
    add('snobol','tests/'+n,fl+[f],T,f'{T}/{n}.in' if os.path.exists(f'{T}/{n}.in') else None)
add('snobol','synthetic/out',[f'{R}/work/out.sno'],R+'/work')
E=f'/home/claude/logo/examples'
for n in ('fact','spiral','star','tree'):
    add('logo','examples/'+n,[f'{E}/{n}.logo',f'{R}/work/o_{n}.svg'],R+'/work',None,f'{R}/work/o_{n}.svg')
add('logo','demo',[],R+'/work',None,R+'/work/logo.svg')
add('logo','synthetic/big',[f'{R}/work/big.logo',f'{R}/work/o_big.svg'],R+'/work',None,f'{R}/work/o_big.svg')
N=int(sys.argv[1]) if len(sys.argv)>1 else 5
res=[]
for lang,name,args,cwd,stdin,of in W:
    t={'base':[],'cre':[]}; c={'base':[],'cre':[]}; h={}
    for i in range(N):
        for var in ('base','cre') if i%2==0 else ('cre','base'):
            el,cpu,out,rc=run(var,lang,args,cwd,stdin,of)
            t[var].append(el); c[var].append(cpu); h[var]=(hashlib.sha1(out).hexdigest()[:8],rc,len(out))
    row=dict(lang=lang,name=name,base=statistics.median(t['base']),cre=statistics.median(t['cre']),
             basecpu=statistics.median(c['base']),crecpu=statistics.median(c['cre']),same=h['base']==h['cre'],rc=h['base'][1],bytes=h['base'][2],
             bmin=min(t['base']),cmin=min(t['cre']))
    res.append(row); print(json.dumps(row),flush=True)
json.dump(res,open(f'{R}/results.json','w'))
