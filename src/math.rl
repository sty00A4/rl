object Math
	const pi is 3.141592653589793
	func floor(s, n:Number) -> Number            n // 1 end
	func ceil(s, n:Number) -> Number   		    n // 1 if n - n // 1 = 0 else n // 1 + 1 end
	func max(s, a:Number, b:Number) -> Number 	a if a > b else b end
	func min(s, a:Number, b:Number) -> Number 	a if a < b else b end
	func abs(s, n:Number) -> Number				n * -1 if n < 0 else n end
	func sum(s, l:List) -> Number
		sum is 0
		for n of l
			sum is sum + n
		end
		return sum
	end
end
math is new Math