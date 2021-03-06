string.letters = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
                   "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
                   "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_" }
string.digits = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
table.copy = function(t)
    if TYPE(t) ~= "table" then return t end
    local newT = {}
    for k, v in pairs(t) do newT[k] = table.copy(v) end
    return newT
end
table.filter = function(t, f)
    local newT = {}
    for k, v in pairs(t) do if f(k, v) then table.insert(newT, v) end end
    if #newT > 0 then return newT end
end
table.find = function(t, f)
    for k, v in pairs(t) do
        local match = f(k, v)
        if match then return match end
    end
    return false
end
table.sub = function(t, i, j)
    if not j then j = #t end
    local nt = {}
    for idx,v in ipairs(t) do if idx >= i and idx <= j then table.insert(nt, v) end end
    return nt
end
string.split = function(s, sep)
    local t, temp = {}, ""
    for i = 1, #s do
        if s:sub(i,i) == sep then
            table.insert(t, temp)
            temp = ""
        else
            temp = temp .. s:sub(i,i)
        end
    end
    table.insert(t, temp)
    return t
end
string.splits = function(s, seps)
    local t, temp = {}, ""
    for i = 1, #s do
        if table.contains(seps, s:sub(i,i)) then
            if #temp > 0 then table.insert(t, temp) end
            temp = ""
        else
            temp = temp .. s:sub(i,i)
        end
    end
    if #temp > 0 then table.insert(t, temp) end
    return t
end
string.join = function(s, t)
    local str = ""
    for _, v in pairs(t) do
        str = str .. tostring(v) .. s
    end
    return str:sub(1, #str-#s)
end
table.contains = function(t, val) return table.find(t, (function(_, v) return v == val end)) end
table.containsStart = function(t, val) return table.find(t, (function(_, v) return v:sub(1,#val) == val end)) end
table.containsKey = function(t, key) return table.find(t, (function(k, _) return k == key end)) end
table.entries = function(t)
    local count = 0
    for _, __ in pairs(t) do count = count + 1 end
    return count
end
table.keyOfValue = function(t, val)
    for k, v in pairs(t) do
        if v == val then return k end
    end
end
local push = table.insert
local pop = table.remove
local concat = table.concat
local copy = table.copy
local filter = table.filter
local find = table.find
local sub = table.sub
local split = string.split
local splits = string.splits
local join = string.join
local contains = table.contains
local containsStart = table.containsStart
local containsKey = table.containsKey
local keyOfValue = table.keyOfValue
TYPE = type
type = function(v)
    if getmetatable(v) then if getmetatable(v).__name then return tostring(getmetatable(v).__name) end end
    return TYPE(v)
end
local function str(val, raw, sep, start, stop, middle)
    if type(sep) ~= "string" then sep = ", " end
    if type(start) ~= "string" then start = "{ " end
    if type(stop) ~= "string" then stop = " }" end
    if type(middle) ~= "string" then middle = "=" end
    if TYPE(val) == "table" then
        if type(val) == "String" and raw then return '"'..tostring(val)..'"' end
        local meta = getmetatable(val) if meta then if meta.__tostring then return tostring(val) end end
        local s = start
        if meta then s = str(meta.__name,raw,sep,start,stop,middle)..s end
        if not next(val) then return s..stop end
        for k, v in pairs(val) do
            if type(k) == "number" then s = s..str(v,raw,sep,start,stop,middle)..sep
            else s = s..str(k,false,sep,start,stop,middle)..middle..str(v,true,sep,start,stop,middle)..sep end
        end
        return s:sub(1, #s-#sep)..stop
    end
    if raw then if type(val) == "string" then return '"'..val..'"' end end
    return tostring(val)
end
local function bool2num(bool) if bool then return 1 else return 0 end end

---Globals
local delimiters = {
    eval = { "(", ")" },
    idxList = { "[", "]" },
    list = { "{", "}" }
}
local words = {
    kw = {
        assign = "is", cast = "as", inc = "inc", dec = "dec", with = "with", to = "to", contain = "in",
        ["return"] = "return", ["and"] = "and", ["or"] = "or", ["xor"] = "xor", ["not"] = "not",
        ["end"] = "end", ["if"] = "if", ["else"] = "else", ["elif"] = "elif", ["while"] = "while",
        ["for"] = "for", of = "of", func = "func", ["break"] = "break", skip = "skip",
        switch = "switch", default = "default", assert = "assert", object = "object",
        new = "new", const = "const", global = "global", use = "use",
    },
    bool = { "true", "false" },
    null = "null",
    type = { number = "Number", string = "String", bool = "Bool", type = "Type", null = "Null", list = "List",
             range = "Range", func = "Func", luaFunc = "LuaFunc", objectDef = "ObjectDef" }
}
local symbols = {
    nl = ";", rep = ":", sep = ",", safe = "?", index = ".", into = "->", addr = "&",
    add = "+", sub = "-", mul = "*", div = "/", idiv = "//", pow = "**", mod = "%",
    eq = "=", ne = "!=", lt = "<", gt = ">", le = "<=", ge = ">="
}

local function Position(idx, ln, col, fn, text)
    return setmetatable(
            {
                idx = idx, ln = ln, col = col, fn = fn, text = text,
                copy = function(s) return Position(s.idx, s.ln, s.col, s.fn, s.text) end,
                sub = function(s) return s.text:sub(s.idx,s.idx) end,
                advance = function(s)
                    s.idx = s.idx + 1
                    s.col = s.col + 1
                    if s:sub() == "\n" then
                        s.ln = s.ln + 1
                        s.col = 0
                    end
                end,
            },
            { __name = "Position" }
    )
end
local function PositionRange(start, stop)
    return setmetatable(
            {
                start = start:copy(), stop = stop:copy(), fn = start.fn, text = start.text,
                copy = function(s) return PositionRange(s.start:copy(), s.stop:copy()) end,
                sub = function(s) return s.text:sub(s.start.idx,s.stop.idx) end
            },
            { __name = "PositionRange" }
    )
end
--TODO: better errors
local function Error(type_, details, pr)
    local fn, ftext = "<unknown>", ""
    if pr then pr = pr:copy() fn = pr.fn ftext = pr.text end
    return setmetatable(
            { type = type_, details = details, pr = pr, fn = fn, text = ftext,
              copy = function(s) return Error(s.type, s.details, s.pr) end },
            { __name = "Error", __tostring = function(s)
                local errStr = s.type..": "..s.details.."\n"
                if not s.pr then return errStr end
                errStr = errStr.."in "..s.fn.."\n"
                local lines = split(s.text, "\n")
                local ln, line = 1
                local newLines, startLn, stopLn = {}, s.pr.start.ln, s.pr.stop.ln
                while ln <= #lines do
                    line = lines[ln]
                    push(newLines, tostring(ln).."\t"..line)
                    if ln >= startLn and ln <= stopLn then
                        local underline = ""
                        for col = 1, #line do
                            local start, stop = 0, #line
                            if s.pr.start.ln == ln then start = s.pr.start.col end
                            if s.pr.stop.ln == ln then stop = s.pr.stop.col end
                            if col >= start and col <= stop then underline=underline.."~"
                            else underline=underline.." " end
                        end
                        push(newLines, " \t"..underline)
                        stopLn=stopLn+1
                    end
                    ln=ln+1
                end
                lines = newLines
                local region = sub(lines, startLn, stopLn)
                local text = join("\n", region)
                errStr = errStr.."\n"..text
                return errStr
            end }
    )
end


---Lexer
local function Token(type_, value, pr)
    return setmetatable(
            { type = type_, value = value, pr = pr, copy = function(s) return Token(s.type, s.value, s.pr:copy()) end },
            { __name = "Token", __tostring = function(s)
                if s.value then return "["..str(s.type)..":"..str(s.value).."]" end
                return "["..str(s.type).."]"
            end, __eq = function(s, o)
                if type(o) == "Token" then
                    if o.value and s.value then return s.type == o.type and s.value == o.value end
                    return s.type == o.type
                end
                return false
            end }
    )
end

local function lex(fn, text)
    local tokens, pos, char = {}, Position(0, 1, 0, fn, text), ""
    local function advance() pos:advance() char = pos:sub() end
    advance()
    local function main()
        if char == "#" then while char ~= "\n" and char ~= "" do advance() end advance() return end
        if contains({ " ", "\t", "\r" }, char) then advance() return end
        if char == "\n" then push(tokens, Token("nl", nil, PositionRange(pos:copy(), pos:copy()))) advance() return end
        if contains(string.digits, char) then
            local start = pos:copy()
            local number = char
            local dots = 0
            local base = 10
            advance()
            while contains(string.digits, char) or char == "." do
                if char == "." then dots = dots + 1 end
                number = number .. char
                advance()
            end
            if char == "x" and number == "0" then
                advance()
                base = 16
                number = ""
                while contains(string.digits, char) or contains(sub(string.letters,1,5)) do
                    number = number .. char
                    advance()
                end
            end
            local stop = pos:copy()
            if base == 16 then
                if dots > 0 then return Error("syntax error", "cannot have dots in hex number", PositionRange(start, stop)) end
            else
                if dots > 1 then return Error("syntax error", "too many dots in number", PositionRange(start, stop)) end
            end
            if dots > 0 then push(tokens, Token("number", tonumber(number), PositionRange(start, stop)))
            else push(tokens, Token("number", tonumber(number, base), PositionRange(start, stop))) end
            return
        end
        if char == '"' then
            local start = pos:copy()
            local str_ = ""
            advance()
            while char ~= '"' and #char > 0 do
                if char == "\\" then
                    advance()
                    if char == "n" then str_ = str_ .. "\n"
                    elseif char == "t" then str_ = str_ .. "\t"
                    elseif char == "r" then str_ = str_ .. "\r"
                    else str_ = str_ .. char end
                    advance()
                else
                    str_ = str_ .. char
                    advance()
                end
            end
            advance()
            local stop = pos:copy()
            push(tokens, Token("string", str_, PositionRange(start, stop))) return
        end
        for name, delim in pairs(delimiters) do
            if char == delim[1] then push(tokens, Token(name, "in", PositionRange(pos, pos))) advance() return end
            if char == delim[2] then push(tokens, Token(name, "out", PositionRange(pos, pos))) advance() return end
        end
        if containsStart(symbols, char) then
            local start = pos:copy()
            local symbol = char
            advance()
            while containsStart(symbols, symbol .. char) and #char > 0 do
                symbol = symbol .. char
                advance()
            end
            local stop = pos:copy()
            for name, s in pairs(symbols) do
                if s == symbol then
                    if type(name) == "number" then
                        push(tokens, Token("symbol", symbol, PositionRange(start, stop))) return
                    else
                        push(tokens, Token(name, s, PositionRange(start, stop))) return
                    end
                end
            end
            return Error("syntax error", "unrecognized symbol '"..symbol.."'", PositionRange(start, stop))
        end
        if contains(string.letters, char) then
            local start = pos:copy()
            local word = char
            advance()
            while contains(string.letters, char) or contains(string.digits, char) do
                word = word .. char
                advance()
            end
            local stop = pos:copy()
            for name, group in pairs(words) do
                if type(group) == "table" then
                    for name2, kw in pairs(group) do
                        if type(name2) == "number" then
                            if word == kw then push(tokens, Token(name, word, PositionRange(start, stop))) return end
                        else
                            if word == kw then push(tokens, Token(name, name2, PositionRange(start, stop))) return end
                        end
                    end
                else
                    if group == word then push(tokens, Token(name, nil, PositionRange(start, stop))) return end
                end
            end
            push(tokens, Token("name", word, PositionRange(start, stop))) return
        end
        return Error("syntax error", "unrecognizable character '"..char.."'", PositionRange(pos, pos))
    end
    while #char > 0 do local err = main() if err then return nil, err end end
    push(tokens, Token("eof",nil,PositionRange(pos:copy(), pos:copy())))
    return tokens
end


---Parser
local function Node(name, args, pr)
    return setmetatable(
            { name = name, args = args, pr = pr },
            { __name = "Node", __tostring = function(s)
                return "("..s.name..":"..str(s.args, nil, " ", "", "")..")"
            end }
    )
end

local function parse(tokens)
    local idx, tok = 0
    local function update() tok=tokens[idx] end
    local function advance() idx=idx+1 update() end
    advance()
    local statements, statement, expr, typecast, logic, comp, contain, range, arith, term, factor, power, call, safe,
    idxList, addr, index, atom, ifExpr, whileExpr, forExpr, func, anonFunc, switch, object
    local function binOp(f1, ops, f2)
        if not f2 then f2 = f1 end
        local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
        local left, right, opTok, err
        left, err = f1() if err then return nil, err end
        while contains(ops, tok) do
            opTok = tok:copy()
            advance()
            stop = tok.pr.stop:copy()
            right, err = f2() if err then return nil, err end
            stop = tok.pr.stop:copy()
            left = Node("binOp", { opTok, left, right }, PositionRange(start, stop))
        end
        return left
    end
    object = function()
        local start= tok.pr.start:copy()
        advance()
        local nodes, nameNode, err = {}, {}
        nameNode, err = atom() if err then return nil, err end
        if nameNode.name ~= "name" then return nil, Error("syntax error", "expected name", nameNode.pr:copy()) end
        if tok ~= Token("nl") then return nil, Error("syntax error", "expected new line", tok.pr:copy()) end
        advance()
        local stop = tok.pr.stop:copy()
        while tok ~= Token("kw","end") do
            local node node, err = statement() if err then return nil, err end
            push(nodes, node)
            while tok == Token("nl") do advance() end
        end
        stop = tok.pr.stop:copy()
        advance()
        return Node("object",{ nameNode, nodes },PositionRange(start, stop))
    end
    switch = function()
        local start = tok.pr.start:copy()
        advance()
        local node, cases, bodies, case, body, default, err = nil, {}, {}
        node, err = expr() if err then return nil, err end
        if tok ~= Token("nl") then return nil, Error("syntax error", "expected new line", tok.pr:copy()) end
        while tok == Token("nl") do advance() end
        while tok ~= Token("kw","end") do
            if tok == Token("kw","default") then
                advance()
                default, err = statement() if err then return nil, err end
                while tok == Token("nl") do advance() end
                if tok ~= Token("kw","end") then return nil, Error("syntax error", "expected '"..words.kw["end"].."'", tok.pr:copy()) end
                break
            end
            case, err = expr() if err then return nil, err end
            push(cases, case)
            if tok ~= Token("rep") then return nil, Error("syntax error", "expected '"..symbols.rep.."'", tok.pr:copy()) end
            advance()
            body, err = statement() if err then return nil, err end
            push(bodies, body)
            while tok == Token("nl") do advance() end
        end
        local stop = tok.pr.stop:copy()
        advance()
        return Node("switch",{ node, cases, bodies, default },PositionRange(start, stop))
    end
    forExpr = function()
        local start= tok.pr.start:copy()
        advance()
        local nameNode, iterator, body, err
        nameNode, err = expr() if err then return nil, err end
        if tok == Token("kw","of") then
            advance()
            iterator, err = expr() if err then return nil, err end
        end
        local stop
        if tok == Token("nl") then
            body, err = statements({ Token("kw","end") }) if err then return nil, err end
            stop = tok.pr.stop:copy()
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        else
            body, err = statement() if err then return nil, err end
            stop = tok.pr.stop:copy()
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        end
        if iterator then return Node("forOf",{ nameNode, iterator, body }, PositionRange(start, stop))
        else return Node("for",{ nameNode, body }, PositionRange(start, stop)) end
    end
    whileExpr = function()
        local start= tok.pr.start:copy()
        advance()
        local condNode, body, err
        condNode, err = expr() if err then return nil, err end
        if tok == Token("nl") then
            advance()
            body, err = statements({ Token("kw","end") }) if err then return nil, err end
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        else
            body, err = statement() if err then return nil, err end
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        end
        return Node("while",{ condNode, body },PositionRange(start, tok.pr.stop:copy()))
    end
    ifExpr = function()
        local start= tok.pr.start:copy()
        local condNodes, bodyNodes, condNode, bodyNode, elseNode, err = {}, {}
        local stop = tok.pr.stop:copy()
        while not contains({ Token("kw","else"), Token("kw","end") }, tok) do
            advance()
            condNode, err = expr() if err then return nil, err end
            push(condNodes, condNode)
            stop = tok.pr.stop:copy()
            if tok == Token("nl") then
                while tok == Token("nl") do advance() end
                bodyNode, err = statements({ Token("kw","elif"), Token("kw","else"), Token("kw","end") }) if err then return nil, err end
                push(bodyNodes, bodyNode)
            else
                bodyNode, err = statement() if err then return nil, err end
                push(bodyNodes, bodyNode)
            end
            while tok == Token("nl") do advance() end
            stop = tok.pr.stop:copy()
        end
        if tok == Token("kw","else") then
            advance()
            if tok == Token("nl") then
                while tok == Token("nl") do advance() end
                elseNode, err = statements({ Token("kw","elif"), Token("kw","else"), Token("kw","end") }) if err then return nil, err end
            else
                elseNode, err = statement() if err then return nil, err end
            end
        end
        stop = tok.pr.stop:copy()
        if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        return Node("if", { condNodes, bodyNodes, elseNode }, PositionRange(start, stop))
    end
    anonFunc = function()
        local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
        local vars, varTypes, values, mustAssign, body, type_, err = {}, {}, {}, false
        advance()
        if tok ~= Token("eval","in") then return nil, Error("syntax error", "expected '"..delimiters.eval[1].."'", tok.pr:copy()) end
        advance()
        while true do
            local var, varType, value
            var, err = atom() if err then return nil, err end
            if var.name ~= "name" then return nil, Error("syntax error", "expected name, got "..str(var.name), var.pr:copy()) end
            push(vars, var)
            if tok == Token("rep") then
                advance()
                varType, err = atom() if err then return nil, err end
                if varType.name ~= "name" and varType.name ~= "type" then return nil, Error("syntax error", "expected name, got "..str(varType.name), varType.pr:copy()) end
                varTypes[var.args[1].value] = varType
            end
            if tok == Token("kw","assign") then
                mustAssign = true
                advance()
                value, err = expr() if err then return nil, err end
                values[var.args[1].value] = value
            else if mustAssign then return nil, Error("syntax error", "expected assignment of name", tok.pr:copy()) end end
            if tok == Token("eval","out") then advance() break end
            if tok ~= Token("sep") then return nil, Error("syntax error", "expected '"..symbols.sep.."'", tok.pr:copy()) end
            advance()
        end
        if tok == Token("into") then
            advance()
            type_, err = atom() if err then return nil, err end
            if type_.name ~= "type" and type_.name ~= "name" then return nil, Error("syntax error", "expected type, got "..str(type_.name), type_.pr:copy()) end
        end
        if tok == Token("nl") then
            while tok == Token("nl") do advance() end
            body, err = statements({ Token("kw","end") }) if err then return nil, err end
            stop = tok.pr.stop:copy()
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
            return Node("func",{ nil, vars, varTypes, values, body, type_ },PositionRange(start, stop))
        end
        body, err = expr() if err then return nil, err end
        stop = tok.pr.stop:copy()
        if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        return Node("func",{ nil, vars, varTypes, values, body, type_ },PositionRange(start, stop))
    end
    func = function(global)
        local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
        advance()
        local name, vars, varTypes, values, mustAssign, body, type_, err = nil, {}, {}, {}, false
        name, err = atom() if err then return nil, err end
        if name.name ~= "name" then return nil, Error("syntax error", "expected name, got "..str(name.name), name.pr:copy()) end
        if tok ~= Token("eval","in") then return nil, Error("syntax error", "expected '"..delimiters.eval[1].."'", tok.pr:copy()) end
        advance()
        while true do
            if tok == Token("eval","out") then advance() break end
            local var, varType, value
            var, err = atom() if err then return nil, err end
            if var.name ~= "name" then return nil, Error("syntax error", "expected name, got "..str(var.name), var.pr:copy()) end
            push(vars, var)
            if tok == Token("rep") then
                advance()
                varType, err = atom() if err then return nil, err end
                if varType.name ~= "name" and varType.name ~= "type" then return nil, Error("syntax error", "expected name, got "..str(varType.name), varType.pr:copy()) end
                varTypes[var.args[1].value] = varType
            end
            if tok == Token("kw","assign") then
                mustAssign = true
                advance()
                value, err = expr() if err then return nil, err end
                values[var.args[1].value] = value
            else if mustAssign then return nil, Error("syntax error", "expected assignment of name", tok.pr:copy()) end end
            if tok == Token("eval","out") then advance() break end
            if tok ~= Token("sep") then return nil, Error("syntax error", "expected '"..symbols.sep.."'", tok.pr:copy()) end
            advance()
        end
        if tok == Token("into") then
            advance()
            type_, err = atom() if err then return nil, err end
            if type_.name ~= "type" and type_.name ~= "name" then return nil, Error("syntax error", "expected type, got "..str(type_.name), type_.pr:copy()) end
        end
        if tok == Token("nl") then
            while tok == Token("nl") do advance() end
            body, err = statements({ Token("kw","end") }) if err then return nil, err end
            stop = tok.pr.stop:copy()
            if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
            return Node("func",{ name, vars, varTypes, values, body, type_, global },PositionRange(start, stop))
        end
        body, err = expr() if err then return nil, err end
        stop = tok.pr.stop:copy()
        if tok == Token("kw","end") then advance() else return nil, Error("syntax error","expected '"..words.kw["end"].."'", tok.pr:copy()) end
        return Node("func",{ name, vars, varTypes, values, body, type_, global },PositionRange(start, stop))
    end
    atom = function()
        local tok_ = tok:copy()
        if tok_.type == "number" then advance() return Node("number", { tok_:copy() }, tok_.pr:copy()) end
        if tok_.type == "bool" then advance() return Node("bool", { tok_:copy() }, tok_.pr:copy()) end
        if tok_.type == "string" then advance() return Node("string", { tok_:copy() }, tok_.pr:copy()) end
        if tok_.type == "type" then advance() return Node("type", { tok_:copy() }, tok_.pr:copy()) end
        if tok_.type == "name" then advance() return Node("name", { tok_:copy() }, tok_.pr:copy()) end
        if tok_.type == "null" then advance() return Node("null", { tok_:copy() }, tok_.pr:copy()) end
        if tok_ == Token("eval","in") then
            advance()
            local node, err = expr() if err then return nil, err end
            if tok ~= Token("eval","out") then return nil, Error("syntax error", "expected "..delimiters.eval[2], tok.pr:copy()) end
            advance()
            return node
        end
        if tok_ == Token("list","in") then
            local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
            advance()
            local list = {}
            while tok ~= Token("eof") and tok ~= Token("list","out") do
                while tok.type == "nl" do advance() end
                local node, err = expr() if err then return nil, err end
                stop = tok.pr.stop:copy()
                while tok.type == "nl" do advance() end
                push(list, node)
                if tok == Token("list","out") then stop = tok.pr.stop:copy() break end
                if tok ~= Token("sep") then return nil, Error("syntax error", "expected '"..symbols.sep.."' or "..delimiters.list[2], tok.pr:copy()) end
                advance()
            end
            advance()
            return Node("list", list, PositionRange(start, stop))
        end
        if tok_ == Token("kw","func") then return anonFunc() end
        return nil, Error("syntax error", "expected number/bool/string/type/name/null", tok.pr:copy())
    end
    index = function() return binOp(atom, { Token("index") }) end
    addr = function()
        if tok == Token("addr") then
            local start = tok.pr.start:copy()
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = index() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("addr", { node }, PositionRange(start, stop))
        end
        return index()
    end
    idxList = function()
        local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
        local node, err = addr() if err then return nil, err end
        if tok == Token("idxList","in") then
            advance()
            local indexNode indexNode, err = expr() if err then return nil, err end
            if tok ~= Token("idxList","out") then return nil, Error("syntax error", "expected "..delimiters.idxList[2], tok.pr:copy()) end
            stop = tok.pr.stop:copy()
            advance()
            return Node("idxList", { node, indexNode }, PositionRange(start, stop))
        end
        return node
    end
    safe = function()
        if tok == Token("safe") then
            local start = tok.pr.start:copy()
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = idxList() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("safe", { node }, PositionRange(start, stop))
        end
        return idxList()
    end
    call = function()
        local start, stop = tok.pr.start:copy(), tok.pr.stop:copy()
        local node, err = safe() if err then return nil, err end
        if tok == Token("eval","in") then
            advance()
            local args = {}
            while tok ~= Token("eval","out") do
                local argNode argNode, err = expr() if err then return nil, err end
                push(args, argNode)
                if tok == Token("sep") then advance() end
            end
            stop = tok.pr.stop:copy() advance()
            return Node("call", { node, args }, PositionRange(start, stop))
        end
        return node
    end
    power = function() return binOp(call, { Token("pow") }) end
    factor = function()
        if tok == Token("sub") then
            local opTok = tok:copy()
            local start = tok.pr.start:copy()
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = factor() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("unaryOp", { opTok, node }, PositionRange(start, stop))
        end
        return power()
    end
    term = function() return binOp(factor, { Token("mul"), Token("div"), Token("idiv"), Token("mod") }) end
    arith = function() return binOp(term, { Token("add"), Token("sub") }) end
    range = function() return binOp(arith, { Token("kw","to") }) end
    typecast = function() return binOp(range, { Token("kw","cast") }) end
    contain = function() return binOp(typecast, { Token("kw","contain") }) end
    comp = function() return binOp(contain, { Token("eq"), Token("ne"), Token("lt"), Token("gt"),
                                              Token("le"), Token("ge") }) end
    logic = function()
        if tok == Token("kw","not") then
            local opTok = tok:copy()
            local start = tok.pr.start:copy()
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = logic() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("unaryOp", { opTok, node }, PositionRange(start, stop))
        end
        return binOp(comp, { Token("kw","and"), Token("kw","or"), Token("kw","xor") })
    end
    expr = function()
        local start = tok.pr.start:copy()
        if tok == Token("kw","new") then
            advance()
            local node, err = index() if err then return nil, err end
            local stop = tok.pr.stop:copy()
            return Node("new",{ node },PositionRange(start, stop))
        end
        local left, err = logic() if err then return nil, err end
        if tok == Token("kw","if") then
            local opTok = tok:copy()
            advance()
            local opNode opNode, err = expr() if err then return nil, err end
            if tok ~= Token("kw","else") then return nil, Error("syntax error", "expected '"..words.kw["else"].."'", tok.pr:copy()) end
            advance()
            local right right, err = expr() if err then return nil, err end
            local stop = tok.pr.stop:copy()
            return Node("ternOp",{ opTok, opNode, left, right },PositionRange(start, stop))
        end
        if tok == Token("kw","for") then
            local opTok = tok:copy()
            advance()
            local opNode opNode, err = expr() if err then return nil, err end
            if tok == Token("kw","of") then
                advance()
                local right right, err = expr() if err then return nil, err end
                local stop = tok.pr.stop:copy()
                return Node("ternOp",{ opTok, opNode, left, right },PositionRange(start, stop))
            end
            local stop = tok.pr.stop:copy()
            return Node("binOp",{ opTok, left, opNode },PositionRange(start, stop))
        end
        return left
    end
    statement = function()
        local start = tok.pr.start:copy()
        local const, global = false, false
        if tok == Token("kw","if") then return ifExpr() end
        if tok == Token("kw","return") then
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = expr() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("return", { node }, PositionRange(start, stop))
        end
        if tok == Token("kw","while") then return whileExpr() end
        if tok == Token("kw","for") then return forExpr() end
        if tok == Token("kw","inc") then
            advance()
            local nameNode, err = index() if err then return nil, err end
            return Node("inc",{ nameNode },PositionRange(start, tok.pr.stop:copy()))
        end
        if tok == Token("kw","dec") then
            advance()
            local nameNode, err = index() if err then return nil, err end
            return Node("dec",{ nameNode },PositionRange(start, tok.pr.stop:copy()))
        end
        if tok == Token("kw","break") then local tok_=tok:copy() advance() return Node("break",{ tok_:copy() },tok_.pr:copy()) end
        if tok == Token("kw","skip") then local tok_=tok:copy() advance() return Node("skip",{ tok_:copy() },tok_.pr:copy()) end
        if tok == Token("kw","switch") then return switch() end
        if tok == Token("kw","assert") then
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = expr() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("assert", { node }, PositionRange(start, stop))
        end
        if tok == Token("kw","use") then
            advance()
            local paths, stop = {}, tok.pr.stop:copy()
            while tok ~= Token("nl") and tok ~= Token("eof") do
                if tok == Token("sep") then advance() end
                local path, last = ""
                while tok ~= Token("sep") and tok ~= Token("nl") and tok ~= Token("eof") do
                    if tok.type == "name" then
                        if last == "name" then return nil, Error("syntax error", "expected '"..symbols.index.."' or new line",tok.pr:copy()) end
                        path = path .. tok.value
                        stop = tok.pr.stop:copy()
                        last = tok.type
                    elseif tok.type == "index" then
                        if last == "index" then return nil, Error("syntax error", "expected name or new line",tok.pr:copy()) end
                        path = path .. "/"
                        stop = tok.pr.stop:copy()
                        last = tok.type
                    else
                        return nil, Error("syntax error", "expected name or '"..symbols.index.."'",tok.pr:copy())
                    end
                    advance()
                end
                if path == "" then return nil, Error("syntax error", "expected name or index") end
                push(paths, path)
            end
            return Node("use",paths,PositionRange(start, stop))
        end
        if tok == Token("kw","object") then return object() end
        if tok == Token("kw","global") then advance() global = true end
        if tok == Token("kw","func") then return func(global) end
        if tok == Token("kw","const") then advance() const = true end
        local node, err = expr() if err then return nil, err end
        if tok == Token("kw","assign") then
            advance()
            local value value, err = expr() if err then return nil, err end
            return Node("assign",{node,value,const,global},PositionRange(node.pr.start:copy(),value.pr.stop:copy()))
        end
        return node
    end
    statements = function(stopTokens)
        local errStr, start, stop = "", tok.pr.start:copy(), tok.pr.stop:copy()
        if stopTokens then
            for _, t in pairs(stopTokens) do
                if t.value then errStr=errStr.."'"..tostring(t.value).."'/" else errStr=errStr..tostring(t.type).."/" end
            end
        end
        errStr=errStr:sub(1,#errStr-1)
        if errStr == "" then errStr = "end of line" end
        local body = {}
        while true do
            while tok == Token("nl") do advance() end
            if stopTokens then if contains(stopTokens, tok) then break end else if tok == Token("eof") then break end end
            if tok == Token("eof") then return nil, Error("syntax error", "expected "..errStr, tok.pr:copy()) end
            stop = tok.pr.stop:copy()
            local node, err = statement() if err then return nil, err end
            stop = tok.pr.stop:copy()
            push(body, node)
            if stopTokens then if contains(stopTokens, tok) then break end else if tok == Token("eof") then break end end
            if tok ~= Token("nl") then return nil, Error("syntax error", "expected new line", tok.pr:copy()) end
        end
        if #body > 0 then
            if #body == 1 then return body[1] end
            return Node("body", body, PositionRange(start, stop))
        end
    end
    if tok == Token("eof") then return end
    local node, err = statements() if err then return nil, err end
    if tok ~= Token("eof") then return nil, Error("syntax error", "unexpected token", tok.pr:copy()) end
    return node
end


---Interpret
-- Values
local Number, Bool, String, Type, Null, List, Range, Func, LuaFunc, ObjectDef, Object
Number = function(number)
    if number == math.floor(number) then number = math.floor(number) end
    return setmetatable(
            { value = number, copy = function(s) return Number(s.value) end,
              toNumber = function(s) return s:copy() end,
              toString = function(s) return String(tostring(s.value)) end,
              toBool = function(s) return Bool(s.value ~= 0) end,
              toList = function(s) return List({ s:copy() }) end,
              toType = function() return Type("number") end
            },
            { __name = "Number", __tostring = function(s) return tostring(s.value) end }
    )
end
Bool = function(bool)
    return setmetatable(
            { value = bool, copy = function(s) return Bool(s.value) end,
              toNumber = function(s) if s.value then return Number(1) else return Number(0) end end,
              toString = function(s) return String(tostring(s.value)) end,
              toBool = function(s) return s:copy() end,
              toList = function(s) return List({ s:copy() }) end,
              toType = function() return Type("bool") end
            },
            { __name = "Bool", __tostring = function(s) return tostring(s.value) end }
    )
end
String = function(str_)
    return setmetatable(
            { value = str_, copy = function(s) return String(s.value) end,
              toNumber = function(s)
                  local value = s.value:match("^%-?%d+$")
                  if value then return Number(tonumber(value)) end
              end,
              toString = function(s) return s:copy() end,
              toBool = function(s)
                  return Bool(#s.value ~= 0)
              end,
              toList = function(s)
                  local list = {}
                  for i = 1, #s.value do push(list, String(s.value:sub(i,i))) end
                  return List(list)
              end,
              toType = function() return Type("string") end
            },
            { __name = "String", __tostring = function(s) return tostring(s.value) end }
    )
end
Type = function(type_)
    return setmetatable(
            { value = type_, copy = function(s) return Type(s.value) end,
              toString = function(s) return String(s.value) end,
              toBool = function() return Bool(true) end,
              toList = function(s) return List({ s:copy() }) end,
              toType = function() return Type("type") end
            },
            { __name = "Type", __tostring = function(s) return tostring(s.value) end }
    )
end
Null = function()
    return setmetatable(
            { copy = function() return Null() end,
              toNumber = function() return Number(0) end,
              toString = function() return String("null") end,
              toBool = function() return Bool(false) end,
              toList = function() return List({}) end,
              toType = function() return Type("null") end
            },
            { __name = "Null", __tostring = function() return "null" end }
    )
end
List = function(values)
    return setmetatable(
            { values = values, copy = function(s)
                local list = {}
                for _, v in ipairs(s.values) do push(list, v:copy()) end
                return List(list)
            end,
              toString = function(s) return String(str(s.values)) end,
              toBool = function() return Bool(true) end,
              toList = function(s) return s:copy() end,
              toType = function() return Type("list") end
            },
            { __name = "List", __tostring = function(s) return str(s.values, true) end }
    )
end
Range = function(start, stop)
    return setmetatable(
            { start = start, stop = stop, copy = function(s) return Range(s.start, s.stop) end,
              toString = function(s) return String(str(s)) end,
              toBool = function() return Bool(true) end,
              toList = function(s)
                  local list = {}
                  local dir = 1
                  if s.start > s.stop then dir = -1 end
                  for i = s.start, s.stop, dir do push(list, Number(i)) end
                  return List(list)
              end,
              toType = function() return Type("range") end
            },
            { __name = "Range", __tostring = function(s) return str(s.start)..".."..str(s.stop) end }
    )
end
Func = function(vars, varTypes, values, body, returnType)
    return setmetatable(
            { vars = vars, varTypes = varTypes, values = values, body = body, returnType = returnType,
              copy = function(s) return Func(s.vars, s.varTypes, s.values, s.body:copy(), s.returnType:copy()) end,
              toString = function(s) return String(str(s)) end,
              toBool = function() return Bool(true) end,
              toType = function() return Type("func") end
            },
            { __name = "Func", __tostring = function(s)
                local str_ = "<func("
                for _, name in ipairs(s.vars) do str_ = str_ .. name.args[1].value .. ", " end
                if #s.vars > 0 then str_ = str_:sub(1,#str_-2) .. ")" else str_ = str_ .. ")" end
                if s.returnType then str_ = str_ .. "->" .. s.returnType.value end
                return str_ .. ">"
            end }
    )
end
LuaFunc = function(vars, varTypes, values, func, returnType)
    return setmetatable(
            { vars = vars, varTypes = varTypes, values = values, func = func, returnType = returnType, copy = function(s) return LuaFunc(copy(s.vars), s.func) end,
              toString = function(s) return String(str(s)) end,
              toBool = function() return Bool(true) end,
              toType = function() return Type("luaFunc") end
            },
            { __name = "LuaFunc", __tostring = function(s)
                local str_ = "<lua-func("
                for _, name in ipairs(s.vars) do str_ = str_ .. name .. ", " end
                if #s.vars > 0 then str_ = str_:sub(1,#str_-2) .. ")" else str_ = str_ .. ")" end
                if s.returnType then str_ = str_ .. "->" .. s.returnType.value end
                return str_ .. ">"
            end }
    )
end
ObjectDef = function(name, vars, funcs, consts)
    return setmetatable(
            { name = name, vars = vars, funcs = funcs, consts = consts, copy = function(s) ObjectDef(s.name, s.vars, s.funcs) end,
              toString = function(s) return String(tostring(s)) end,
              toBool = function() return Bool(true) end,
              toType = function(s) return Type(s.name) end
            },
            { __name = "ObjectDef", __tostring = function(s)
                local subs = ""
                for k, _ in pairs(s.vars) do subs = subs..k.."," end
                for k, _ in pairs(s.consts) do subs = subs..k.."," end
                for k, _ in pairs(s.funcs) do subs = subs..k.."," end
                subs = subs:sub(1,#subs-1)
                return "<objectDef-"..s.name.."("..subs..")>"
            end }
    )
end
Object = function(objectName, varAddrs, consts)
    if not consts then consts = {} end
    return setmetatable(
            { name = objectName, varAddrs = varAddrs, consts = consts,
              toString = function(s) return String(tostring(s)) end,
              toBool = function() return Bool(true) end,
              toType = function(s) return Type(s.name) end,
              copy = function(s)
                  local newVarAddrs = {}
                  for k, v in pairs(s.varAddrs) do newVarAddrs[k] = v end
                  local newConsts = {}
                  for k, v in pairs(s.consts) do newConsts[k] = v end
                  return Object(s.name, newVarAddrs, newConsts)
              end,
              deleteAddrs = function(s, memory)
                  for _, addr in pairs(s.varAddrs) do
                      if type(memory[addr]) == "Object" then memory[addr]:deleteAddrs(memory) end
                      memory[addr] = nil
                  end
              end
            },
            { __name = "Object", __tostring = function(s) return "<object-"..s.name..">" end }
    )
end

local function Memory(memory)
    if not memory then memory = {} end
    return setmetatable(memory, { __name = "Memory", __index = function(s,k)
        if k == "new" then return function(self) return #self+1 end end
        return rawget(s, k)
    end })
end
-- built-in functions
local memIota, memStart
local MEMORY MEMORY = Memory({
    -- print
    LuaFunc({ "value" }, { }, { }, function(_, _, args)
        print(str(args[1]))
        return Null()
    end, Type("null")),
    -- debugMem
    LuaFunc({ }, { }, { }, function()
        print("\n- memory -")
        for i = memStart, #MEMORY do print(i, str(MEMORY[i],true)) end
        print()
        return Null()
    end, Type("null")),
    -- debugScopes
    LuaFunc({ }, { }, { }, function(scopes)
        print("- scopes -", table.entries(scopes.scopes))
        for i, scope in ipairs(scopes.scopes) do if i ~= table.entries(scopes.scopes) then print(i, scope.label, str(scope.vars)) end end
        print()
        return Null()
    end, Type("null")),
    -- fromAddr
    LuaFunc({ "addr" }, { Type("number") }, { }, function(_, node, args)
        if type(args[1]) ~= "Number" then return nil, false, Error("lua func error", "expected Number as #1 argument", node.pr:copy()) end
        if not MEMORY[math.floor(args[1].value)] then return nil, false, Error("lua func error", "memory addres "..str(args[1]).." doesn't exist", node.pr:copy()) end
        return MEMORY[math.floor(args[1].value)]:copy()
    end),
    -- setAddr
    LuaFunc({ "var", "addr" }, { Type("string"), Type("number") }, { }, function(scopes, node, args)
        if type(args[1]) ~= "String" then return nil, false, Error("lua func error", "expected String as #1 argument", node.pr:copy()) end
        if type(args[2]) ~= "Number" then return nil, false, Error("lua func error", "expected Number as #2 argument", node.pr:copy()) end
        local _, err = scopes:setAddr(node, args[1].value, args[2].value, MEMORY) if err then return nil, false, err end
        return Null()
    end, Type("null")),
    -- len
    LuaFunc({ "value" }, { }, { }, function(_, node, args)
        if type(args[1]) == "List" then return Number(#args[1].values) end
        if type(args[1]) == "String" then return Number(#args[1].value) end
        return nil, false, Error("value error", "cannot get length of "..type(args[1]), node.pr:copy())
    end, Type("number")),
    -- type
    LuaFunc({ "value" }, { }, { }, function(scopes, node, args)
        if args[1] == nil then error("argument is nil", 2) end
        if words.type[args[1].value] then return Type(args[1].value) end
        if type(args[1]) == "Object" then return Type(args[1].name) end
        if contains(words.type, type(args[1])) then return Type(keyOfValue(words.type, type(args[1]))) end
        local value, err = scopes:get(args[1].name, MEMORY) if err then return nil, false, err end
        return Type(keyOfValue(words.type, type(value)))
    end, Type("type")),
})
memIota, memStart = #MEMORY, #MEMORY + 1
-- LIST push
push(MEMORY, LuaFunc({ "list", "value" }, { Type("list") }, { }, function(_, _, args)
    push(args[1].values, args[2]:copy())
    return args[1]:copy()
end, Type("list")))
-- LIST pop
push(MEMORY, LuaFunc({ "list", "index" }, { Type("list"), Type("number") }, { index=Number(-1) }, function(_, _, args)
    if args[2].value < 0 then args[2].value = #args[1].values + 1 + args[2].value end
    local value = pop(args[1].values, args[2].value)
    return value:copy()
end))
-- LIST join
push(MEMORY, LuaFunc({ "list", "string" }, { Type("list"), Type("string") }, { string=String("") }, function(_, _, args)
    return String((args[2].value):join(args[1].values))
end, Type("string")))
-- STRING split
push(MEMORY, LuaFunc({ "string", "sep" }, { Type("string"), Type("string") }, { }, function(_, _, args)
    local list = split(args[1].value, args[2].value)
    for i = 1, #list do list[i] = String(list[i]) end
    return List(list)
end, Type("list")))
local function iotaMem() memIota = memIota+1 return memIota end
local ListFuncs = { push = iotaMem(), pop = iotaMem(), join = iotaMem() }
local StringFuncs = { split = iotaMem() }
local function Scope(vars, consts, label)
    if not label then label = "<sub>" end
    if not vars then vars = {} end
    if not consts then consts = {} end
    return setmetatable(
            { vars = vars, consts = consts, label = label, copy = function(s) return Scope(s.vars, s.consts, s.label) end,
              get = function(s, name)
                  if s.vars[name] then return s.vars[name] end
                  if s.consts[name] then return s.consts[name] end
              end,
              set = function(s, name, addr, const)
                  s.vars[name] = addr
                  if const then s.consts[name] = addr end
              end,
              isConst = function(s, addr) return contains(s.consts, addr) end
            },
            { __name = "Scope", __tostring = function(s)
                return "Scope("..str(s.vars)..")"
            end }
    )
end
local function Scopes(scopes, globals, globConsts)
    if not scopes then scopes = {} end
    if not globals then globals = {} end
    if not globConsts then globConsts = {} end
    return setmetatable(
            { scopes = scopes, globals = globals, globConsts = globConsts, copy = function(s)
                local a = {}
                for i, v in ipairs(s.scopes) do a[i] = v:copy() end
                return Scopes(a, s.globals)
            end, setAddr = function(s, node, name, addr, memory)
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if scope then
                    if not memory[addr] then return nil, Error("name error", "name address "..str(addr).." doesn't exist in memory", node.pr:copy()) end
                    scope.vars[name] = addr
                    return
                end
                return nil, Error("name error", "name '"..name.."' cannot be found", node.pr:copy())
            end, getAddr = function(s, node, name)
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if scope then return scope.vars[name] end
                if s.globals[name] then return s.globals[name] end
                return nil, Error("name error", "name '"..name.."' cannot be found", node.pr:copy())
            end, get = function(s, node, memory)
                local name = node
                if type(node) ~= "string" then name = node.args[1].value end
                if s.globals[name] then
                    if memory[s.globals[name]] then return memory[s.globals[name]] end
                    return nil, Error("name error", "address of '"..name.."' doesn't exist in memory", node.pr:copy())
                end
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if scope then
                    local addr = scope:get(name)
                    if memory[addr] then return memory[addr] end
                    return nil, Error("name error", "address of '"..name.."' doesn't exist in memory", node.pr:copy())
                end
                if type(node) ~= "string" then return nil, Error("name error", "name '"..name.."' is not registered", node.pr:copy()) end
                return nil, Error("name error", "name '"..name.."' is not registered")
            end, isConst = function(s, addr)
                local scope
                for _, v in ipairs(s.scopes) do
                    if contains(v.consts, addr) then scope=v end
                end
                if scope then return scope:isConst(addr) end
                return false
            end, set = function(s, nameNode, value, memory, const, global)
                local name = nameNode
                if type(nameNode) ~= "string" then name = nameNode.args[1].value end
                if s.globConsts[name] then
                    if type(nameNode) ~= "string" then return nil, Error("name error", "variable is constant", nameNode.pr:copy()) end
                    return nil, Error("name error", "variable is constant")
                end
                if global then
                    local addr, err = memory:new() if err then return nil, err end
                    if s.globals[name] then return nil, Error("name error", "'"..name.."' is already global") end
                    s.globals[name] = addr
                    if const then s.globConsts[name] = addr end
                end
                local addr, err
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if not scope then
                    if s.globals[name] then
                        addr = s.globals[name]
                        memory[s.globals[name]] = value
                        return addr
                    end
                    scope = s.scopes[#s.scopes]
                    addr, err = memory:new() if err then return nil, err end
                else
                    addr = scope.vars[name]
                    if scope.consts[name] then
                        if type(nameNode) ~= "string" then return nil, Error("name error", "variable is constant", nameNode.pr:copy()) end
                        return nil, Error("name error", "variable is constant")
                    end
                end
                scope:set(name, addr, const)
                memory[addr] = value
                return addr
            end,
              new = function(s, scope) s.scopes[#s.scopes+1] = scope end,
              drop = function(s)
                  for _, addr in pairs(s.scopes[#s.scopes].vars) do
                      if type(MEMORY[addr]) == "Object" then MEMORY[addr]:deleteAddrs(MEMORY) end
                      MEMORY[addr] = nil
                  end
                  pop(s.scopes)
              end
            },
            { __name = "Scopes", __tostring = function(s)
                return "Scopes("..str(s.scopes)..")"
            end }
    )
end

local function stdScope()
    local scopes = Scopes({ Scope() })
    scopes.globals["print"] = 1
    scopes.globals["debugMem"] = 2
    scopes.globals["debugScopes"] = 3
    scopes.globals["fromAddr"] = 4
    scopes.globals["setAddr"] = 5
    scopes.globals["len"] = 6
    scopes.globals["type"] = 7
    return scopes
end

local function interpret(ast)
    math.randomseed(os.time())
    local scopes = stdScope()
    local nodes, visit
    local function eq(v1, v2)
        if not v1 or not v2 then return Bool(false) end
        if type(v1) == "List" and type(v2) == "List" then
            for i, v in ipairs(v1.values) do
                local equal, err = eq(v, v2.values[i]) if err then return nil, false, err end
                if not equal.value then return Bool(false) end
            end
            return Bool(true)
        end
        if type(v1) == "Range" and type(v2) == "Range" then
            return Bool(v1.start == v2.start and v1.stop == v2.stop)
        end
        if v1.value and v2.value then return Bool(v1.value == v2.value) end
        return Bool(false)
    end
    local function typeOfType(type_)
        if type_ == nil then error("argument is nil", 2) end
        if words.type[type_.value] then return words.type[type_.value] end
        if type(type_) == "Object" then return type_.name end
        if contains(words.type, type(type_)) then return type(type_) end
        local value, err = scopes:get(type_.name, MEMORY) if err then return nil, false, err end
        return type(value)
    end
    nodes = {
        notImplemented = function(node)
            print(str(node))
            return nil, false, Error("not implemented", node.name, node.pr:copy()) end,
        number = function(node) return Number(node.args[1].value) end,
        bool = function(node) return Bool(node.args[1].value == words.bool[1]) end,
        string = function(node) return String(node.args[1].value) end,
        type = function(node) return Type(node.args[1].value) end,
        null = function() return Null() end,
        name = function(node)
            local value, err = scopes:get(node, MEMORY) if err then return nil, false, err end
            if value then return value else return Null() end
        end,
        list = function(node)
            local list, value, err = {}
            for _, v in pairs(node.args) do
                value, __, err = visit(v) if err then return nil, false, err end
                push(list, value)
            end
            return List(list)
        end,
        safe = function(node)
            local value, _, err = visit(node.args[1])
            if err then
                if contains({"name error","index error"}, err.type) then return Null() end
                return nil, false, err
            end
            return value
        end,
        addr = function(node)
            if node.args[1].name == "binOp" and node.args[1].args[1] == Token("index") then
                return nodes.indexAddr(node.args[1])
            end
            local name = node.args[1]
            local addr, err = scopes:getAddr(node, name.args[1].value) if err then return nil, false, err end
            return Number(addr)
        end,
        ["return"] = function(node)
            local value, _, err = visit(node.args[1]) if err then return value, true, err end
            return value, true
        end,
        assign = function(node)
            local value, _, err = visit(node.args[2]) if err then return nil, false, err end
            if node.args[1].name == "binOp" and node.args[1].args[1] == Token("index") then
                if node.args[3] then return nil, false, Error("assign error", "cannot assign index as constant") end
                if node.args[4] then return nil, false, Error("assign error", "cannot assign index as global") end
                local addr addr, _, err = nodes.indexAddr(node.args[1], true) if err then return nil, false, err end
                addr = addr.value
                if typeOfType(MEMORY[addr]) ~= typeOfType(value) then
                    return nil, false, Error("value error", "expected "..typeOfType(MEMORY[addr])..", got "..typeOfType(value), node.args[2].pr:copy())
                end
                MEMORY[addr] = value:copy()
                return value
            end
            if node.args[1].name == "name" then
                _, err = scopes:set(node.args[1], value, MEMORY, node.args[3], node.args[4]) if err then return nil, false, err end
                return value
            end
            if node.args[1].name == "idxList" then
                if node.args[3] then return nil, false, Error("assign error", "cannot assign list index as constant") end
                if node.args[4] then return nil, false, Error("assign error", "cannot assign list index as global") end
                if node.args[1].args[1].name ~= "name" then return nil, false, Error("assign error", "expected name", node.args[1].args[1].pr:copy()) end
                local list list, _, err = visit(node.args[1].args[1]) if err then return nil, false, err end
                if type(list) ~= "List" then return nil, false, Error("index error", "expected List, got "..typeOfType(list), node.args[1].args[1].pr:copy()) end
                local index index, _, err = visit(node.args[1].args[2]) if err then return nil, false, err end
                if type(index) ~= "Number" then return nil, false, Error("index error", "expected Number, got "..typeOfType(index), node.args[1].args[2].pr:copy()) end
                list.values[math.floor(index.value)+1] = value
                _, err = scopes:set(node.args[1].args[1], list, MEMORY) if err then return nil, false, err end
                return value
            end
            return nil, false, Error("assign error", "expected name or index", node.args[1].pr:copy())
        end,
        cast = function(node)
            local value, type_, err
            value, _, err = visit(node.args[2]) if err then return nil, false, err end
            type_, _, err = visit(node.args[3]) if err then return nil, false, err end
            if type(type_) ~= "Type" then return nil, false, Error("cast error", "expected Type", node.args[2].pr:copy()) end
            local castValue
            if typeOfType(type_) == type(value) then return value end
            if type_.value == "type" and value.toType then castValue = value:toType() end
            if type_.value == "null" then castValue = Null() end
            if type_.value == "number" and value.toNumber then castValue = value:toNumber() end
            if type_.value == "bool" and value.toBool then castValue = value:toBool() end
            if type_.value == "string" and value.toString then castValue = value:toString() end
            if type_.value == "list" and value.toList then castValue = value:toList() end
            if not castValue then return nil, false, Error("cast error", "cannot cast "..type(value).." to "..typeOfType(type_), node.pr:copy()) end
            return castValue
        end,
        index = function(node)
            if node.args[3].name ~= "name" then return nil, false, Error("index error", "expected name", node.args[3].pr:copy()) end
            local head, index, addr, err
            head, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(head) == "Object" then
                index = node.args[3].args[1].value
                addr = head.varAddrs[index]
                if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not in '"..head.name.."'", node.pr:copy()) end
                if not MEMORY[addr] then return nil, false, Error("memory error", "address "..str(addr).." doesn't exists", node.pr:copy()) end
                return MEMORY[addr]
            end
            if type(head) == "List" then
                index = node.args[3].args[1].value
                addr = ListFuncs[index]
                if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not a list function", node.pr:copy()) end
                if not MEMORY[addr] then return nil, false, Error("memory error", "address "..str(addr).." doesn't exists", node.pr:copy()) end
                return MEMORY[addr]
            end
            if type(head) == "String" then
                index = node.args[3].args[1].value
                addr = StringFuncs[index]
                if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not a string function", node.pr:copy()) end
                if not MEMORY[addr] then return nil, false, Error("memory error", "address "..str(addr).." doesn't exists", node.pr:copy()) end
                return MEMORY[addr]
            end
            return nil, false, Error("index error", "cannot index "..type(head), node.args[2].pr:copy())
        end,
        indexAddr = function(node, checkConst)
            if node.args[3].name ~= "name" then return nil, false, Error("index error", "expected name", node.args[3].pr:copy()) end
            local head, index, addr, err
            head, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(head) ~= "Object" then return nil, false, Error("index error", "cannot index "..type(head), node.args[2].pr:copy()) end
            index = node.args[3].args[1].value
            addr = head.varAddrs[index]
            if checkConst then if head.consts[index] then return nil, false, Error("name error", "cannot change value of constant name", node.pr:copy()) end end
            if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not in '"..head.name.."'", node.pr:copy()) end
            return Number(addr)
        end,
        idxList = function(node)
            local list, index, err
            list, _, err = visit(node.args[1]) if err then return nil, false, err end
            index, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(list) == "List" then
                if type(index) == "Number" then
                    if index.value < 0 then index.value = #list.values + index.value end
                    local value = list.values[math.floor(index.value)+1]
                    if value == nil then return nil, false, Error("index error", "index out of range", node.pr:copy()) end
                    return value:copy()
                end
                if type(index) == "Range" then
                    local min, max = index.start, index.stop
                    if min < 0 then min = #list.values + min end if max < 0 then max = #list.values + max end
                    local value = List(sub(list.values, min+1, max+1))
                    return value:copy()
                end
            end
            if type(list) == "String" then
                if type(index) == "Number" then
                    if index.value < 0 then index.value = #list.value + index.value end
                    local value = String(list.value:sub(index.value+1,index.value+1))
                    if value == nil then return nil, false, Error("index error", "index out of range", node.pr:copy()) end
                    return value:copy()
                end
                if type(index) == "Range" then
                    local min, max = index.start, index.stop
                    if min < 0 then min = #list.value + min end if max < 0 then max = #list.value + max end
                    local value = String(list.value:sub(min+1, max+1))
                    return value:copy()
                end
            end
            if type(list) == "Range" then
                if type(index) == "Number" then
                    if index.value < 0 then index.value = #list:toList().values + index.value end
                    local value = list:toList().values[math.floor(index.value)+1]
                    if value == nil then return nil, false, Error("index error", "index out of range", node.pr:copy()) end
                    return value:copy()
                end
            end
            return nil, false, Error("index error", "cannot list-index "..type(list).." with "..type(index))
        end,
        binOp = function(node)
            local opTok = node.args[1]
            local left, right, err
            if opTok.type == "index" then return nodes.index(node) end
            left, _, err = visit(node.args[2]) if err then return nil, false, err end
            right, _, err = visit(node.args[3]) if err then return nil, false, err end
            if opTok.type == "add" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value + right.value)
                end
                if type(left) == "String" and type(right) == "String" then
                    return String(left.value .. right.value)
                end
            end
            if opTok.type == "sub" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value - right.value)
                end
            end
            if opTok.type == "mul" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value * right.value)
                end
            end
            if opTok.type == "div" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value / right.value)
                end
            end
            if opTok.type == "idiv" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value // right.value)
                end
            end
            if opTok.type == "pow" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value ^ right.value)
                end
            end
            if opTok.type == "mod" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Number(left.value % right.value)
                end
            end
            if opTok.type == "eq" then return eq(left, right) end
            if opTok.type == "ne" then return Bool(not eq(left, right).value) end
            if opTok.type == "lt" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Bool(left.value < right.value)
                end
            end
            if opTok.type == "gt" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Bool(left.value > right.value)
                end
            end
            if opTok.type == "le" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Bool(left.value <= right.value)
                end
            end
            if opTok.type == "ge" then
                if type(left) == "Number" and type(right) == "Number" then
                    return Bool(left.value >= right.value)
                end
            end
            if opTok.type == "kw" then
                if opTok.value == "to" then
                    if type(left) == "Number" and type(right) == "Number" then
                        return Range(left.value, right.value)
                    end
                end
                if opTok.value == "and" then
                    if type(left) == "Bool" and type(right) == "Bool" then
                        return Bool(left.value and right.value)
                    end
                end
                if opTok.value == "or" then
                    if type(left) == "Bool" and type(right) == "Bool" then
                        return Bool(left.value or right.value)
                    else
                        if left.toBool then if left:toBool().value then return left:copy()
                        else return right:copy() end end
                    end
                end
                if opTok.value == "xor" then
                    if type(left) == "Bool" and type(right) == "Bool" then
                        return Bool((left.value or right.value) and not(left.value and right.value))
                    end
                end
                if opTok.value == "contain" then
                    if type(right) == "List" then
                        for _, v in ipairs(right.values) do
                            local value = Bool(false)
                            value, _, err = eq(v, left)
                            if value.value then return Bool(true) end
                        end
                        return Bool(false)
                    end
                    if type(right) == "Range" then
                        if type(left) == "Number" then
                            return Bool(left.value >= right.start and left.value <= right.stop)
                        end
                    end
                end
                if opTok.value == "cast" then return nodes.cast(node) end
                if opTok.value == "for" then
                    if type(right) == "Range" then
                        local values = {}
                        local dir = 1 if right.start > right.stop then dir = -1 end
                        for i = right.start, right.stop, dir do
                            local value value, _, err = visit(node.args[2]) if err then return nil, false, err end
                            push(values, value)
                        end
                        return List(values)
                    end
                    if type(right) == "Number" then
                        local values = {}
                        for i = 1, right.value do
                            local value value, _, err = visit(node.args[2]) if err then return nil, false, err end
                            push(values, value)
                        end
                        return List(values)
                    end
                end
            end
            local name = opTok.type
            if opTok.value then name = opTok.value end
            return nil, false, Error("operation error", "binary operation '"..name.."' cannot be performed with "..type(left).." and "..type(right), node.pr:copy())
        end,
        unaryOp = function(node)
            local opTok = node.args[1]
            local value, err = visit(node.args[2]) if err then return nil, false, err end
            if opTok.type == "sub" then if type(value) == "Number" then return Number(-value.value) end end
            if opTok.type == "kw" then
                if opTok.value == "not" then
                    if type(value) == "Bool" then return Bool(not value.value)
                    else if value.toBool then return Bool(not value:toBool().value) end end
                end
            end
            local name = opTok.type
            if opTok.value then name = opTok.value end
            return nil, false, Error("operation error", "unary operation '"..name.."' cannot be performed with "..type(value), node.pr:copy())
        end,
        ternOp = function(node)
            local opTok, opNode, left, right = node.args[1], node.args[2], node.args[3], node.args[4]
            if opTok == Token("kw","if") then
                local opValue, _, err = visit(opNode) if err then return nil, false, err end
                if not opValue.toBool then return nil, false, Error("cast error", "cannot cast "..typeOfType(opValue).." to Bool", opNode.pr:copy()) end
                if opValue:toBool().value then return visit(left) end
                return visit(right)
            end
            if opTok == Token("kw","for") then
                if opNode.name ~= "name" then return nil, false, Error("iteration error", "expected name", opNode.pr:copy()) end
                local iterator, _, err = visit(right) if err then return nil, false, err end
                local values = {}
                if type(iterator) == "Range" then
                    local dir = 1 if iterator.start > iterator.stop then dir = -1 end
                    for i = iterator.start, iterator.stop, dir do
                        scopes:new(Scope())
                        _, err = scopes:set(opNode, Number(i), MEMORY) if err then return nil, false, err end
                        local value value, _, err = visit(left) if err then return nil, false, err end
                        push(values, value)
                        scopes:drop()
                    end
                    return List(values)
                end
                if type(iterator) ~= "List" then
                    if not iterator.toList then return nil, false, Error("value error", "cannot cast "..type(iterator).." to List", iterNode.pr:copy()) end
                    iterator = iterator:toList()
                end
                if type(iterator) == "List" then
                    for i, x in ipairs(iterator.values) do
                        scopes:new(Scope(nil, nil, "iterator"))
                        _, err = scopes:set(opNode, x:copy(), MEMORY) if err then return nil, false, err end
                        local value value, _, err = visit(left) if err then return nil, false, err end
                        push(values, value)
                        scopes:drop()
                    end
                    return List(values)
                end
            end
            local name = opTok.type
            if opTok.value then name = opTok.value end
            return nil, false, Error("operation error", "ternary operation '"..name.."' cannot be performed", node.pr:copy())
        end,
        body = function(node, name, breakable, skippable)
            scopes:new(Scope(nil, nil, name))
            for _, n in ipairs(node.args) do
                local value, returning, err = visit(n) if err then return nil, false, err end
                if returning then
                    if returning == "break" and breakable then scopes:drop() return value, returning end
                    if returning == "skip" and skippable then scopes:drop() return value, returning end
                    if returning == true then scopes:drop() return value, returning end
                end
            end
            scopes:drop()
            return Null()
        end,
        ["if"] = function(node)
            local condNodes, bodyNodes, elseNode = node.args[1], node.args[2], node.args[3]
            local idx
            for i, condNode in ipairs(condNodes) do
                local value, _, err = visit(condNode) if err then return nil, false, err end
                if not value.toBool then return nil, false, Error("value error", "expected Bool", condNode.pr:copy()) end
                if value:toBool().value then idx = i break end
            end
            if idx then return visit(bodyNodes[idx])
            else if elseNode then return visit(elseNode) end end
            return Null()
        end,
        ["while"] = function(node)
            local condNode, bodyNode, returning, value = node.args[1], node.args[2]
            local cond, _, err = visit(condNode) if err then return nil, false, err end
            if not cond.toBool then return nil, false, Error("value error", "expected Bool", condNode.pr:copy()) end
            while cond.value do
                value, returning, err = visit(bodyNode, "while", true, true) if err then return nil, false, err end
                if returning then
                    if returning == "break" then break end
                    if returning ~= "skip" then return value end
                end
                cond, _, err = visit(condNode) if err then return nil, false, err end
                if not cond.toBool then return nil, false, Error("value error", "expected Bool", condNode.pr:copy()) end
            end
            return Null()
        end,
        ["for"] = function(node)
            local rangeNode, bodyNode, returning, value = node.args[1], node.args[2]
            local range, _, err = visit(rangeNode) if err then return nil, false, err end
            if type(range) ~= "Range" then return nil, false, Error("value error", "expected Range", rangeNode.pr:copy()) end
            local dir = 1 if range.start > range.stop then dir = -1 end
            for i = range.start, range.stop, dir do
                value, returning, err = visit(bodyNode, "for", true, true) if err then return nil, false, err end
                if returning then
                    if returning == "break" then break end
                    if returning ~= "skip" then return value end
                end
            end
            return Null()
        end,
        ["forOf"] = function(node)
            local nameNode, iterNode, bodyNode, returning, value = node.args[1], node.args[2], node.args[3]
            if nameNode.name ~= "name" then return nil, false, Error("iteration error", "expected name", nameNode.pr:copy()) end
            local iterator, _, err = visit(iterNode) if err then return nil, false, err end
            if type(iterator) == "Range" then
                local dir = 1 if iterator.start > iterator.stop then dir = -1 end
                for i = iterator.start, iterator.stop, dir do
                    scopes:new(Scope())
                    _, err = scopes:set(nameNode, Number(i), MEMORY) if err then return nil, false, err end
                    value, returning, err = visit(bodyNode, "forOf", true, true) if err then return nil, false, err end
                    scopes:drop()
                    if returning then
                        if returning == "break" then break end
                        if returning ~= "skip" then return value end
                    end
                end
                return Null()
            end
            if type(iterator) ~= "List" then
                if not iterator.toList then return nil, false, Error("value error", "cannot cast "..type(iterator).." to List", iterNode.pr:copy()) end
                iterator = iterator:toList()
            end
            if type(iterator) == "List" then
                for i, x in ipairs(iterator.values) do
                    scopes:new(Scope(nil, nil, "iterator"))
                    _, err = scopes:set(nameNode, x:copy(), MEMORY) if err then return nil, false, err end
                    value, returning, err = visit(bodyNode, "forOf", true, true) if err then return nil, false, err end
                    scopes:drop()
                    if returning then
                        if returning == "break" then break end
                        if returning ~= "skip" then return value end
                    end
                end
                return Null()
            end
            return nil, false, Error("iteration error", "cannot iterate with "..type(iterator), iterNode.pr:copy())
        end,
        ["break"] = function() return Null(), "break" end,
        skip = function() return Null(), "skip" end,
        func = function(node)
            -- 1:name 2:vars 3:varTypes 4:values 5:body 6:type_ 7:global
            local type_, err if node.args[6] then
                type_, _, err = visit(node.args[6]) if err then return nil, false, err end
                if type(type_) ~= "Type" then return nil, false, Error("value error", "expected Type", node.args[6].pr:copy()) end
            end
            local func = Func(node.args[2], node.args[3], node.args[4], node.args[5], type_)
            if node.args[1] then if containsKey(scopes.globals, node.args[1].args[1].value) then return nil, false, Error("name error", "function variable is a global variable", node.args[6].pr:copy()) end end
            if node.args[1] then _, err = scopes:set(node.args[1], func, MEMORY, true, node.args[7]) if err then return nil, false, err end end
            return func
        end,
        luaFunc = function(node)
            -- 1:name 2:vars 3:varTypes 4:values 5:body 6:type_ 7:global
            local type_, err if node.args[6] then
                type_, _, err = visit(node.args[6]) if err then return nil, false, err end
                if type(type_) ~= "Type" then return nil, false, Error("value error", "expected Type", node.args[6].pr:copy()) end
            end
            local func = LuaFunc(node.args[2], node.args[3], node.args[4], node.args[5], type_)
            if node.args[1] then if containsKey(scopes.globals, node.args[1].args[1].value) then return nil, false, Error("name error", "function variable is a global variable", node.args[6].pr:copy()) end end
            if node.args[1] then _, err = scopes:set(node.args[1], func, MEMORY, true, node.args[7]) if err then return nil, false, err end end
            return func
        end,
        call = function(node)
            local func, args, err = nil, {}
            local selfCall, headAddr = false
            if node.args[1].name == "binOp" then if node.args[1].args[1] == Token("index") then
                selfCall = true
                if node.args[1].args[2].name == "binOp" and node.args[1].args[2].args[1] == Token("index") then
                    return nodes.indexAddr(node.args[1].args[2])
                end
                local name = node.args[1].args[2]
                if name.name ~= "name" then return nil, false, Error("index error", "expected name as head", name.pr:copy()) end
                headAddr, err = scopes:getAddr(node, name.args[1].value) if err then return nil, false, err end
            end end
            func, _, err = visit(node.args[1]) if err then return nil, false, err end
            if type(func) == "Func" then
                if selfCall then push(args, MEMORY[headAddr]) end
                for _, arg in ipairs(node.args[2]) do
                    local value
                    value, __, err = visit(arg) if err then return nil, false, err end
                    push(args, value)
                end
                local value
                local mainScopes = scopes.scopes
                for i, var in ipairs(func.vars) do
                    if func.varTypes[var.args[1].value] and args[i] then
                        local type_ type_, _, err = visit(func.varTypes[var.args[1].value]) if err then return nil, false, err end
                        if typeOfType(type_) ~= typeOfType(args[i]) then
                            return nil, false, Error("func error","type mismatch for argument #"..str(i-bool2num(selfCall))..", got "..tostring(typeOfType(args[i])).." expected "..tostring(typeOfType(type_)),node.pr:copy())
                        end
                    end
                end
                scopes.scopes = {}
                scopes:new(Scope(nil, nil, "func"))
                scopes.scopes[#scopes.scopes].vars["self"] = headAddr
                for i, var in ipairs(func.vars) do
                    if not args[i] then
                        if not func.values[var.args[1].value] then return nil, false, Error("func error", "too few arguments", node.pr:copy()) end
                        args[i], _, err = visit(func.values[var.args[1].value]) if err then return nil, false, err end
                    end
                    if containsKey(scopes.globals, var.args[1].value) then return nil, false, Error("name error", "function variable is a global variable", node.pr:copy()) end
                    _, err = scopes:set(var, args[i], MEMORY) if err then return nil, false, err end
                end
                value, _, err = visit(func.body) if err then return nil, false, err end
                scopes.scopes = mainScopes
                if func.returnType then
                    if type(value) ~= typeOfType(func.returnType) then
                        return nil, false, Error("func error", "returned value isn't "..str(typeOfType(func.returnType))..", got "..type(value), node.pr:copy())
                    end
                end
                return value
            end
            if type(func) == "LuaFunc" then
                if selfCall then push(args, MEMORY[headAddr]) end
                for _, arg in ipairs(node.args[2]) do
                    local value
                    value, __, err = visit(arg) if err then return nil, false, err end
                    push(args, value)
                end
                local value
                local mainScopes = scopes.scopes
                for i, var in ipairs(func.vars) do
                    if func.varTypes[var] and args[i] then
                        local type_ type_, _, err = visit(func.varTypes[var]) if err then return nil, false, err end
                        if typeOfType(type_) ~= typeOfType(args[i]) then
                            return nil, false, Error("func error","type mismatch for argument #"..str(i-bool2num(selfCall))..", got "..tostring(typeOfType(args[i])).." expected "..tostring(typeOfType(type_)),node.pr:copy())
                        end
                    end
                end
                scopes.scopes = {}
                scopes:new(Scope(nil, nil, "func"))
                scopes.scopes[#scopes.scopes].vars["self"] = headAddr
                for i, var in ipairs(func.vars) do
                    if not args[i] then
                        if not func.values[var] then return nil, false, Error("lua func error", "too few arguments", node.pr:copy()) end
                        args[i], _, err = func.values[var] if err then return nil, false, err end
                    end
                    if containsKey(scopes.globals, var) then return nil, false, Error("name error", "function variable is a global variable", node.pr:copy()) end
                    _, err = scopes:set(var, args[i], MEMORY) if err then return nil, false, err end
                end
                value, _, err = func.func(scopes, node, args) if err then return nil, false, err end
                scopes.scopes = mainScopes
                if func.returnType then if type(value) ~= typeOfType(func.returnType) then
                    return nil, false, Error("func error", "returned value isn't "..str(typeOfType(func.returnType))..", got "..type(value), node.pr:copy())
                end end
                return value
            end
            return nil, false, Error("value error", "expected Func/LuaFunc", node.args[1].pr:copy())
        end,
        inc = function(node)
            local addr, _, err = nodes.addr(node) if err then return nil, false, err end
            if MEMORY[addr.value] then
                if type(MEMORY[addr.value]) == "Number" then
                    MEMORY[addr.value].value = MEMORY[addr.value].value + 1
                    return MEMORY[addr.value]
                end
                return nil, false, Error("value error", "cannot increment value of type "..type(MEMORY[addr.value]),node.pr:copy())
            end
            return nil, false, Error("name error", "address "..str(addr.value).." is not in memory", node.args[1].pr.copy())
        end,
        dec = function(node)
            local addr, _, err = nodes.addr(node) if err then return nil, false, err end
            if MEMORY[addr.value] then
                if type(MEMORY[addr.value]) == "Number" then
                    MEMORY[addr.value].value = MEMORY[addr.value].value - 1
                    return MEMORY[addr.value]
                end
                return nil, false, Error("value error", "cannot decrement value of type "..type(MEMORY[addr.value]),node.pr:copy())
            end
            return nil, false, Error("name error", "address "..str(addr.value).." is not in memory", node.args[1].pr.copy())
        end,
        switch = function(node)
            local valueNode, cases, bodies, default = table.unpack(node.args)
            local value, _, err = visit(valueNode) if err then return nil, false, err end
            for i, caseNode in ipairs(cases) do
                local case case, _, err = visit(caseNode) if err then return nil, false, err end
                if eq(value, case).value then return visit(bodies[i]) end
            end
            if default then return visit(default) end
            return Null()
        end,
        assert = function(node)
            local value, _, err = visit(node.args[1]) if err then return value, true, err end
            if not value.toBool then return nil, false, Error("cast error", "cannot cast "..typeOfType(value).." to Bool", node.args[1].pr:copy()) end
            if not value:toBool().value then return nil, false, Error("assertion", "not true", node.pr:copy()) end
            return value
        end,
        object = function(node)
            local nameNode, nodes_, err = table.unpack(node.args)
            local name, vars, consts, funcs = nameNode.args[1].value, {}, {}, {}
            for _, n in ipairs(nodes_) do
                if n.name == "func" then
                    local funcName = n.args[1].args[1].value
                    local type_ if n.args[6] then
                    type_, _, err = visit(n.args[6]) if err then return nil, false, err end
                    if type(type_) ~= "Type" then return nil, false, Error("value error", "expected Type", n.args[6].pr:copy()) end
                end
                    local func = Func(n.args[2], n.args[3], n.args[4], n.args[5], type_) if err then return nil, false, err end
                    funcs[funcName] = func
                elseif n.name == "luaFunc" then
                    local funcName = n.args[1].args[1].value
                    local type_ if n.args[6] then
                    type_, _, err = visit(n.args[6]) if err then return nil, false, err end
                    if type(type_) ~= "Type" then return nil, false, Error("value error", "expected Type", n.args[6].pr:copy()) end
                end
                    local func = LuaFunc(n.args[2], n.args[3], n.args[4], n.args[5], type_) if err then return nil, false, err end
                    funcs[funcName] = func
                elseif n.name == "assign" then
                    local varName = n.args[1].args[1].value
                    local value = visit(n.args[2]) if err then return nil, false, err end
                    if n.args[4] then return nil, false, Error("name error", "cannot create global variable inside object", n.pr:copy()) end
                    if n.args[3] then consts[varName] = value else vars[varName] = value end
                else
                    return nil, false, Error("object error", "expected assignment or function", n.pr:copy())
                end
            end
            _, err = scopes:set(name,ObjectDef(name, vars, funcs, consts),MEMORY,true,true) if err then return nil, false, err end
            return scopes:get(name, MEMORY)
        end,
        new = function(node)
            local varAddrs, consts, objectDef, err = {}, {}
            objectDef, err = scopes:get(node.args[1], MEMORY) if err then return nil, false, err end
            for k, v in pairs(objectDef.vars) do
                local addr addr, err = MEMORY:new() if err then return nil, false, err end
                varAddrs[k] = addr
                MEMORY[addr] = v
            end
            for k, v in pairs(objectDef.consts) do
                local addr addr, err = MEMORY:new() if err then return nil, false, err end
                consts[k] = addr
                varAddrs[k] = addr
                MEMORY[addr] = v
            end
            for k, v in pairs(objectDef.funcs) do
                local addr addr, err = MEMORY:new() if err then return nil, false, err end
                varAddrs[k] = addr
                MEMORY[addr] = v
            end
            return Object(node.args[1].args[1].value, varAddrs, consts)
        end,
        use = function(node)
            for _, path in ipairs(node.args) do
                local fn = path
                local luaFile = false
                local file = io.open(fn..".rl", "r")
                if not file then
                    if not pcall(require, fn) then return nil, false, Error("file not found", fn..".lua", path.pr:copy()) end
                    file = require(fn)
                    if type(file) ~= "Node" then return nil, false, Error("file not found", fn..".lua", path.pr:copy()) end
                    local __, __, err = visit(file) if err then return nil, false, err end
                else
                    if not file then return nil, false, Error("file not found", fn..".rl", path.pr:copy()) end
                    local text = file:read("*a")
                    file:close()
                    local tokens, fileAst, err
                    tokens, err = lex(fn, text) if err then return nil, false, err end
                    fileAst, err = parse(tokens) if err then return nil, false, err end
                    if fileAst.name == "body" then
                        for _, n in ipairs(fileAst.args) do
                            if contains({ "assign", "func", "object", "use" }, n.name) then
                                __, __, err = visit(n) if err then return nil, false, err end
                            end
                        end
                    else
                        __, __, err = visit(fileAst) if err then return nil, false, err end
                    end
                end
            end
            return Bool(true)
        end,
    }
    visit = function(node, ...)
        math.random()
        if not node then error("no node given", 2) end
        if nodes[node.name] then return nodes[node.name](node, ...) end
        return nodes.notImplemented(node)
    end
    if not ast then return Null() end
    local value, returning, err = visit(ast) if err then return nil, false, err end
    if not getmetatable(value) then return nil, false, Error("dev error", "value returned is not a metatable") end
    return value, returning, nil, scopes
end

local function run(fn, text)
    local tokens, ast, err
    tokens, err = lex(fn, text) if err then return nil, false, err end
    ast, err = parse(tokens) if err then return nil, false, err end
    return interpret(ast)
end
local function runfile(fn)
    local file = io.open(fn, "r")
    local text = file:read("*a")
    local value, returning, err, scopes = run(fn, text) if err then file:close() print(err) return end
    file:close()
    if returning then print(value) end
    return value, returning, nil, scopes
end

return {
    lex = lex, parse = parse, interpret = interpret, str = str, run = run, runfile = runfile,
    Number = Number, Bool = Bool, String = String, Type = Type, Null = Null, List = List, Range = Range,
    Func = Func, LuaFunc = LuaFunc, Object, ObjectDef, Memory = Memory, Scope = Scope,
    Scopes = Scopes, Token = Token, Node = Node, PositionRange = PositionRange, Position = Position, Error = Error,
    ast2str = function(s, ast)
        if not ast then return "()" end
        if type(ast) == "Node" then
            if ast.name == "number" then return "(" .. ast.args[1].value .. ")" end
            if ast.name == "break" then return "(break)" end
            if ast.name == "skip" then return "(skip)" end
            if ast.name == "bool" then return "(" .. ast.args[1].value .. ")" end
            if ast.name == "string" then return "(\"" .. ast.args[1].value .. "\")" end
            if ast.name == "type" then return "(" .. ast.args[1].value .. ")" end
            if ast.name == "null" then return "(null)" end
            if ast.name == "name" then return "(" .. ast.args[1].value .. ")" end
            if ast.name == "list" then
                local str_ = "({ "
                for _, node in pairs(ast.args) do
                    str_ = str_ .. s(s,node) .. ", "
                end
                return str_ .. "})"
            end
            if ast.name == "safe" then return "(? " .. s(s,ast.args[1]) .. ")" end
            if ast.name == "return" then
                local value = s(s,ast.args[1])
                return "(return "..value..")"
            end
            if ast.name == "assign" then
                local name, value = s(s,ast.args[1]), s(s,ast.args[2])
                return "("..name.." is "..value..")"
            end
            if ast.name == "idxList" then
                local list, index = s(s,ast.args[1]), s(s,ast.args[2])
                return "("..list.." ["..index.."])"
            end
            if ast.name == "binOp" then
                local opTok, left, right = ast.args[1], s(s,ast.args[2]), s(s,ast.args[3])
                local op = opTok.value or opTok.type
                return "("..left.." "..op.." "..right..")"
            end
            if ast.name == "unaryOp" then
                local opTok, node = ast.args[1], s(s,ast.args[2])
                local op = opTok.type if opTok.value then op = opTok.value end
                return "("..op.." "..node..")"
            end
            if ast.name == "body" then
                local str_ = "(\n"
                for _, node in ipairs(ast.args) do
                    str_ = str_ .. s(s,node) .. ";\n"
                end
                return str_ .. ")"
            end
            if ast.name == "if" then
                local str_ = "(if " .. s(s,ast.args[1][1]) .. " " .. s(s,ast.args[2][1]) .. " "
                for i = 2, #ast.args[1] do
                    str_ = str_ .. "elif " .. s(s,ast.args[1][i]) .. " " .. s(s,ast.args[2][i]) .. " "
                end
                if ast.args[3] then
                    str_ = str_ .. "else ".. s(s,ast.args[3]) .. " "
                end
                return str_ .. "end)"
            end
            if ast.name == "while" then return "(while " .. s(s,ast.args[1]) .. " " .. s(s,ast.args[2]) .. "end)" end
            if ast.name == "for" then return "(for " .. s(s,ast.args[1]) .. " " .. s(s,ast.args[2]) .. "end)" end
            if ast.name == "forOf" then return "(for " .. s(s,ast.args[1]) .. " of " .. s(s,ast.args[2]) .. " " .. s(s,ast.args[3]) .. "end)" end
            if ast.name == "func" then
                local str_ = "(func " .. s(s,ast.args[1]) .. " ("
                for _, node in ipairs(ast.args[2]) do str_ = str_ .. s(s,node) .. ", " end
                if #ast.args[2] > 0 then str_ = str_:sub(1,#str_-2) .. ") " else str_ = str_ .. ") " end
                if ast.args[4] then str_ = str_ .. "-> ".. s(s,ast.args[4]) .. " " end
                return str_ .. ": " .. s(s,ast.args[3]) .. "end)"
            end
            if ast.name == "call" then
                local args = ""
                for _, n in ipairs(ast.args[2]) do args = args .. s(s,n) .. ", " end
                if #args > 0 then args = args:sub(1,#args-2) end
                return "( " .. s(s,ast.args[1]) .. "( " .. args .. " ))"
            end
        end
        return str(ast)
    end
}