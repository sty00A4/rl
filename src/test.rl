use std.rand
rand.seed(10)
choice is rand.int(4)
switch choice
	0: print("yes")
	1: print("no")
	2: print("maybe")
	3: print("probably")
	4: print("likely")
	default print("dunno")
end
