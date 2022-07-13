local rl = require("rl")
local create = require("create")
return create:objectInitBody("OS","os",{
    create:luaFunc(
            "time",{"s"},{},{},
            function(scopes, node, args)
                return rl.Number(os.time())
            end,
            "number"
    ),
    create:luaFunc(
            "exit",{"s","code"},{code="number"},{code=rl.Number(0)},
            function(scopes, node, args)
                if args[2] then os.exit(args[2].value) else os.exit() end
            end,
            "null"
    ),
    create:luaFunc(
            "exec",{"s","cmd"},{code="string"},{},
            function(scopes, node, args)
                local success = os.execute(args[2].value)
                return rl.Bool(success)
            end,
            "bool"
    ),
})