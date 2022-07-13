local rl = require("rl")
local create = require("create")
return create:objectInitBody("IO","io",{
    create:luaFunc(
            "input",{"s","text"},{},{text=rl.Null()},
            function(scopes, node, args)
                if type(args[2]) == "String" then io.write(args[2].value) end
                return rl.String(io.read())
            end,
            "string"
    ),
    create:luaFunc(
            "inputNumber",{"s","text"},{},{text=rl.Null()},
            function(scopes, node, args)
                if type(args[2]) == "String" then io.write(args[2].value) end
                local number = io.read("*number")
                if number == nil then return rl.Null() end
                return rl.Number(number)
            end,
            "number"
    ),
    create:luaFunc(
            "write",{"s","text"},{text="string"},{text=rl.String("")},
            function(scopes, node, args)
                io.write(args[2].value)
                return rl.Null()
            end,
            "null"
    ),
})