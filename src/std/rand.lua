local rl = require("rl")
local create = require("create")
return create:objectInitBody("Random","rand",{
    create:luaFunc(
            "int",{"s","a","b"},{a="number"},{b=rl.Null()},
            function(scopes, node, args)
                if type(args[3]) == "Null" then
                    return rl.Number(math.random(0, args[2].value))
                end
                if type(args[3]) == "Number" then
                    return rl.Number(math.random(args[2].value, args[3].value))
                end
                return nil, false, rl.Error("value error", "expected Number as #2 argument, got "..type(args[3]), node.pr:copy())
            end,
            "number"
    ),
    create:luaFunc(
            "seed",{"s","x"},{x="number"},{x=rl.Number(0)},
            function(scopes, node, args) math.randomseed(args[2].value) return rl.Null() end,
            "null"
    )
})