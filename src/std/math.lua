local rl = require("rl")
local create = require("create")
return create:objectInitBody("Math", "math",
        {
            create:assign("pi", create:tokNode(math.pi), true),
            create:assign("tau", create:tokNode(math.pi*2), true),
            create:luaFunc("floor",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.floor(args[2].value))
                    end, "number"
            ),
            create:luaFunc("ceil",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.ceil(args[2].value))
                    end, "number"
            ),
            create:luaFunc("abs",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.abs(args[2].value))
                    end, "number"
            ),
            create:luaFunc("max",{"s","a","b"},{a="number",b="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.max(args[2].value,args[3].value))
                    end, "number"
            ),
            create:luaFunc("min",{"s","a","b"},{a="number",b="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.min(args[2].value,args[3].value))
                    end, "number"
            ),
            create:luaFunc("sum",{"s","l"},{l="list"},{},
                    function(scopes, node, args)
                        local sum = 0
                        for i, n in ipairs(args[2].values) do
                            if type(n) ~= "Number" then return nil, false, rl.Error("value error", "can only sum up numbers", node.pr:copy()) end
                            sum = sum + n.value
                        end
                        return rl.Number(sum)
                    end, "number"
            ),
        })