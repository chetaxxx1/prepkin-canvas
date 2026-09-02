import sheet2
CASES=[]
for ku in (58.0, 42.0, 30.0, 20.0):
    for dg,rc in [(60,1.35),(85,1.55),(105,1.62)]:
        CASES.append((dg,rc,{"fillet":150.0,"thin":0.25,"paw":1.0,"waist":0.6,
                             "k_up":ku},"kup%.0f"%ku))
sheet2.grid(CASES,"diag_kup.png",cols=3,scale=3)
