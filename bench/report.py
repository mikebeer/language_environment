import json,math,sys
r=json.load(open(sys.argv[1]))
agg={}
for x in r:
    print("%-7s %-24s %6.3f %6.3f %+6.1f%%  %s"%(x['lang'],x['name'],x['base'],x['cre'],(x['cre']/x['base']-1)*100,'same' if x['same'] else 'DIFF'))
    agg.setdefault(x['lang'],[]).append(x)
for l,xs in agg.items():
    g=math.exp(sum(math.log(x['cre']/x['base']) for x in xs)/len(xs))
    tb=sum(x['base'] for x in xs); tc=sum(x['cre'] for x in xs)
    print(l,"n=%d geomean %.3f total %.2fs -> %.2fs (%+.1f%%) identical: %s"%(len(xs),g,tb,tc,(tc/tb-1)*100,all(x['same'] for x in xs)))
