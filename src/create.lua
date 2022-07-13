local rl = require("rl")
local MSG = "NO PREVIEW"
local start, stop = rl.Position(1, 1, 1, "math.lua", MSG), rl.Position(#MSG, 1, #MSG, "math.lua", MSG)
local PR = rl.PositionRange(start, stop)
return {
    PR = PR,
    body = function(create, body)
        return rl.Node("body", body, create.PR)
    end,
    tokNode = function(create, value, type_)
        if not type_ then type_ = type(value) end
        return rl.Node(type_,{
            rl.Token(type_,value,create.PR)
        },create.PR)
    end,
    assign = function(create, name, node, const, global)
        return rl.Node("assign",{
            rl.Node("name",{
                rl.Token("name",name,create.PR)
            },create.PR),
            node,
            const,
            global
        },create.PR)
    end,
    luaFunc = function(create, name, vars, varTypes, values, func, type_, global)
        local vars_ = {} for _, v in ipairs(vars) do table.insert(vars_, v) end
        local varTypes_ = {} for k, v in pairs(varTypes) do varTypes_[k] = create:tokNode(v,"type") end
        if type_ then
            return rl.Node("luaFunc",{
                create:tokNode(name,"name"),
                vars_,
                varTypes_,
                values,
                func,
                create:tokNode(type_,"type"),
                global
            },create.PR)
        else
            return rl.Node("luaFunc",{
                create:tokNode(name,"name"),
                vars_,
                varTypes_,
                values,
                func,
                nil,
                global
            },create.PR)
        end
    end,
    luaFuncAnon = function(create, vars, varTypes, values, func, type_)
        local vars_ = {} for _, v in ipairs(vars) do table.insert(vars_, v) end
        local varTypes_ = {} for k, v in pairs(varTypes) do varTypes_[k] = create:tokNode(v,"type") end
        if type_ then
            return rl.Node("luaFunc",{
                nil,
                vars_,
                varTypes_,
                values,
                func,
                create:tokNode(type_,"type")
            },create.PR)
        else
            return rl.Node("luaFunc",{
                nil,
                vars_,
                varTypes_,
                values,
                func,
            },create.PR)
        end
    end,
    object = function(create, name, nodes)
        return rl.Node("object", {
            create:tokNode(name,"name"),
            nodes
        },create.PR)
    end,
    new = function(create, name)
        return rl.Node("new",{ create:tokNode(name,"name") },create.PR)
    end,
    assignObj = function(create, name, objName, const, global)
        return create:assign(name, create:new(objName), const, global)
    end,
    objectInit = function(create, objName, name, nodes)
        return {
            create:object(objName, nodes),
            create:assignObj(name,objName,true,true), -- math is new Math
        }
    end,
    objectInitBody = function(create, objName, name, nodes)
        return create:body(create:objectInit(objName, name, nodes))
    end,
}