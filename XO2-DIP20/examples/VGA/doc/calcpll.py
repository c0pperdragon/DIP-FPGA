def calc(target):
    bestf = 0
    bestvco = 0
    vestdivider = 0
    for multiplier in range(50,100,1):
        vco = 10*multiplier;
        for divider in range(15,100,1):
            f = vco/divider
            if abs(f-target) < abs(bestf-target):
                bestf = f
                bestvco = vco
                bestdivider = divider
    print ("best for ",target,": ",bestvco/10,":",bestdivider,"=", bestvco/bestdivider);

calc(25.175)
calc(15.76)
