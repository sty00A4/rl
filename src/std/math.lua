local rl = require("rl")
local MSG = "NO PREVIEW"
local start, stop = rl.Position(1, 1, 1, "math.lua", MSG), rl.Position(#MSG, 1, #MSG, "math.lua", MSG)
local PR = rl.PositionRange(start, stop)
local function createName(name)
    return rl.Node("name",{
        rl.Token("name",name,PR)
    },PR)
end
local function createType(name)
    return rl.Node("type",{
        rl.Token("type",name,PR)
    },PR)
end
local function create(value, type_)
    if not type_ then type_ = type(value) end
    return rl.Node(type_,{
        rl.Token(type_,value,PR)
    },PR)
end
local function createAssign(name, node, const, global)
    return rl.Node("assign",{
        rl.Node("name",{
            rl.Token("name",name,PR)
        },PR),
        node,
        const,
        global
    },PR)
end
local function createLuaFunc(name, vars, varTypes, values, func, type_)
    local vars_ = {} for _, v in ipairs(vars) do table.insert(vars_, createName(v)) end
    local varTypes_ = {} for k, v in ipairs(varTypes) do varTypes_[k] = createType(v) end
    return rl.Node("luaFunc",{
        createName(name),
        vars_,
        varTypes_,
        values,
        func,
        createType(type_)
    },PR)
end
return rl.Node("body", {
    rl.Node("object", {
        rl.Node("name",{ rl.Token("name","Math",PR) },PR),
        {
            createAssign("pi", create(math.pi), true),
            createAssign("tau", create(math.pi*2), true),
            createLuaFunc("floor",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.floor(args[2].value))
                    end, "number"
            ),
            createLuaFunc("ceil",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.ceil(args[2].value))
                    end, "number"
            ),
            createLuaFunc("abs",{"s","n",},{n="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.abs(args[2].value))
                    end, "number"
            ),
            createLuaFunc("max",{"s","a","b"},{a="number",b="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.max(args[2].value,args[3].value))
                    end, "number"
            ),
            createLuaFunc("min",{"s","a","b"},{a="number",b="number"},{},
                    function(scopes, node, args)
                        return rl.Number(math.min(args[2].value,args[3].value))
                    end, "number"
            ),
            createLuaFunc("sum",{"s","l"},{l="list"},{},
                    function(scopes, node, args)
                        local sum = 0
                        for i, n in ipairs(args[2].values) do
                            if type(n) ~= "Number" then return nil, false, rl.Error("value error", "can only sum up numbers", node.pr:copy()) end
                            sum = sum + n.value
                        end
                        return rl.Number(sum)
                    end, "number"
            ),
        }
    },PR), -- object Math
    rl.Node("assign",{
        rl.Node("name",{
            rl.Token("name","math",PR)
        },PR),
        rl.Node("new",{
            rl.Node("name",{
                rl.Token("name","Math",PR)
            },PR)
        },PR),
        false,
        true
    },PR), -- math is new Math
},PR)