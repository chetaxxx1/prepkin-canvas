import sheet2
CASES=[]
for thin,paw,waist in [(0.55,0.95,0.55),(0.9,0.95,0.55),(0.9,1.05,0.62),(1.2,1.05,0.62)]:
    for dg,rc in [(75,1.50),(85,1.55),(95,1.60)]:
        CASES.append((dg,rc,{"fillet":150.0,"thin":thin,"paw":paw,"waist":waist},
                      "t%.2f p%.2f w%.2f"%(thin,paw,waist)))
sheet2.grid(CASES,"diag_paw.png",cols=3,scale=3)
