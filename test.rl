object Math
	pi is 3.141592653589793
	func floor(self, n:Number) -> Number            n // 1 end
	func ceil(self, n:Number) -> Number   		    n // 1 if n - n // 1 = 0 else n // 1 + 1 end
	func max(self, a:Number, b:Number) -> Number 	a if a > b else b end
	func min(self, a:Number, b:Number) -> Number 	a if a < b else b end
end
math is new Math
return math.min(4, 8)