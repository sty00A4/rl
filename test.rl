func numberName(n:Number) -> String
	switch n
		0: return "zero"
		1: return "one"
		2: return "two"
		3: return "three"
		4: return "four"
		5: return "five"
		6: return "six"
		7: return "seven"
		8: return "eight"
		9: return "nine"
		10: return "ten"
	default return "?" end
end

return numberName(6) + "ty " + numberName(9)
