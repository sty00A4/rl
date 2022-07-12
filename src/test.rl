global const localhost is "127.0.0.1"
func change()
	localhost is "127.0.0.2"
	debugMem()
end
debugMem()
change()
debugMem()
return localhost