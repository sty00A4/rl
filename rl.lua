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
        struct = "struct",
    },
    bool = { "true", "false" },
    null = "null",
    type = { number = "Number", string = "String", bool = "Bool", type = "Type", null = "Null", list = "List",
             range = "Range", func = "Func", luaFunc = "LuaFunc" }
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
                start = start, stop = stop, fn = start.fn, text = start.text,
                copy = function(s) return PositionRange(s.start:copy(), s.stop:copy()) end,
                sub = function(s) return s.text:sub(s.start.idx,s.stop.idx) end
            },
            { __name = "PositionRange" }
    )
end
--TODO: better errors
local function Error(type_, details, pr)
    if pr then pr = pr:copy() end
    return setmetatable(
            { type = type_, details = details, pr = pr, fn = pr.fn, text = pr.text,
              copy = function(s) return Error(s.type, s.details, s.pr) end },
            { __name = "Error", __tostring = function(s)
                local errStr = "in "..s.fn.."\n"..s.type..": "..s.details
                if not s.pr then return errStr end
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
                            if s.pr.stop.ln == ln then stop = s.pr.stop.col-1 end
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
        if char == "#" then while char ~= "\n" do advance() end advance() return end
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
            push(tokens, Token("number", tonumber(number, base), PositionRange(start, stop))) return
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
    idxList, addr, index, atom
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
            while tok ~= Token("eof") do
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
        return nil, Error("syntax error", "expected number/bool/string/type/name/null", tok.pr:copy())
    end
    index = function()
        return binOp(atom, { Token("index") })
    end
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
    expr = function() return logic() end
    statement = function()
        local start = tok.pr.start:copy()
        if tok == Token("kw","if") then
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
            if tok == Token("kw","else") then return nil, Error("syntax error", "expected "..words.kw["end"], tok.pr:copy()) end
            stop = tok.pr.stop:copy()
            advance()
            return Node("if", { condNodes, bodyNodes, elseNode }, PositionRange(start, stop))
        end
        if tok == Token("kw","func") then
            local stop = tok.pr.stop:copy()
            advance()
            local name, vars, body, type_, err = nil, {}
            name, err = atom() if err then return nil, err end
            if name.name ~= "name" then return nil, Error("syntax error", "expected name, got "..str(name.name), name.pr:copy()) end
            if tok ~= Token("eval","in") then return nil, Error("syntax error", "expected '"..delimiters.eval[1].."'", tok.pr:copy()) end
            advance()
            while true do
                local var
                var, err = atom() if err then return nil, err end
                if var.name ~= "name" then return nil, Error("syntax error", "expected name, got "..str(var.name), var.pr:copy()) end
                push(vars, var)
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
                if tok ~= Token("kw","end") then return nil, Error("syntax error", "expected '"..words.kw["end"].."'", tok.pr:copy()) end
                stop = tok.pr.stop:copy()
                advance()
                return Node("func",{ name, vars, body, type_ },PositionRange(start, stop))
            end
            body, err = expr() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("func",{ name, vars, body, type_ },PositionRange(start, stop))
        end
        if tok == Token("kw","return") then
            advance()
            local stop = tok.pr.stop:copy()
            local node, err = expr() if err then return nil, err end
            stop = tok.pr.stop:copy()
            return Node("return", { node }, PositionRange(start, stop))
        end
        if tok == Token("kw","while") then
            advance()
            local condNode, body, err
            condNode, err = expr() if err then return nil, err end
            if tok == Token("nl") then
                advance()
                body, err = statements({ Token("kw","end") }) if err then return nil, err end
                advance()
            else
                body, err = statement() if err then return nil, err end
            end
            return Node("while",{ condNode, body },PositionRange(start, tok.pr.stop:copy()))
        end
        if tok == Token("kw","for") then
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
                advance()
            else
                body, err = statement() if err then return nil, err end
                stop = tok.pr.stop:copy()
            end
            if iterator then return Node("forOf",{ nameNode, iterator, body }, PositionRange(start, stop))
            else return Node("for",{ nameNode, body }, PositionRange(start, stop)) end
        end
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
        if tok == Token("kw","struct") then
            advance()
            local vars, nameNode, var, type_, err = {}
            nameNode, err = atom() if err then return nil, err end
            if nameNode.name ~= "name" then return nil, Error("syntax error", "expected name", nameNode.pr:copy()) end
            if tok ~= Token("nl") then return nil, Error("syntax error", "expected new line", tok.pr:copy()) end
            advance()
            local stop = tok.pr.stop:copy()
            while true do
                if tok == Token("kw","end") then break end
                if tok == Token("eof") then return nil, Error("syntax error", "expected name", tok.pr:copy()) end
                var, err = atom() if err then return nil, err end
                if var.name ~= "name" then return nil, Error("syntax error", "expected name", var.pr:copy()) end
                if tok == Token("rep") then
                    advance()
                    type_, err = atom() if err then return nil, err end
                    if type_.name ~= "type" and type_.name ~= "name" then return nil, Error("syntax error", "expected type", type_.pr:copy()) end
                end
                push(vars, { var, type_ })
                if tok ~= Token("nl") and tok ~= Token("kw","end") then
                    return nil, Error("syntax error", "expected new line or '"..words.kw["end"].."'", tok.pr:copy())
                end
                advance()
            end
            stop = tok.pr.stop:copy()
            advance()
            return Node("struct",{ nameNode, vars },PositionRange(start, stop))
        end
        local node, err = expr() if err then return nil, err end
        if tok == Token("kw","assign") then
            advance()
            local value value, err = expr() if err then return nil, err end
            return Node("assign",{node,value},PositionRange(node.pr.start:copy(),value.pr.stop:copy()))
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
local Number, Bool, String, Type, Null, List, Range, Func, LuaFunc, StructDef, Struct
Number = function(number)
    if number == math.floor(number) then number = math.floor(number) end
    return setmetatable(
            { value = number, copy = function(s) return Number(s.value) end,
              toNumber = function(s) return s:copy() end,
              toString = function(s) return String(tostring(s.value)) end,
              toBool = function(s) return Bool(s.value ~= 0) end,
              toList = function(s) return List({ s:copy() }) end,
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
                  if s.value == "true" then return Bool(true) end
                  if s.value == "false" then return Bool(false) end
              end,
              toList = function(s)
                  local list = {}
                  for i = 1, #s.value do push(list, String(s.value:sub(i,i))) end
                  return List(list)
              end,
            },
            { __name = "String", __tostring = function(s) return tostring(s.value) end }
    )
end
Type = function(type_)
    return setmetatable(
            { value = type_, copy = function(s) return Type(s.value) end,
              toString = function(s) return String(s.value) end,
              toBool = function(s) return Bool(true) end,
              toList = function(s) return List({ s:copy() }) end,
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
              toBool = function(s) return Bool(true) end,
              toList = function(s) return s:copy() end,
            },
            { __name = "List", __tostring = function(s) return str(s.values) end }
    )
end
Range = function(start, stop)
    return setmetatable(
            { start = start, stop = stop, copy = function(s) return Range(s.start, s.stop) end,
              toString = function(s) return String(str(s)) end,
              toBool = function(s) return Bool(true) end,
              toList = function(s)
                  local list = {}
                  local dir = 1
                  if s.start > s.stop then dir = -1 end
                  for i = s.start, s.stop, dir do push(list, Number(i)) end
                  return List(list)
              end,
            },
            { __name = "Range", __tostring = function(s) return str(s.start)..".."..str(s.stop) end }
    )
end
Func = function(vars, body, returnType)
    return setmetatable(
            { vars = vars, body = body, returnType = returnType, copy = function(s) return Func(copy(s.vars), s.body:copy()) end,
              toString = function(s) return String(str(s)) end,
              toBool = function(s) return Bool(true) end,
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
LuaFunc = function(vars, func, returnType)
    return setmetatable(
            { vars = vars, func = func, returnType = returnType, copy = function(s) return LuaFunc(copy(s.vars), s.func) end,
              toString = function(s) return String(str(s)) end,
              toBool = function(s) return Bool(true) end,
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
StructDef = function(name, vars)
    return setmetatable(
            { name = name, vars = vars, copy = function(s) return StructDef(s.name, copy(s.vars)) end },
            { __name = "StructDef", __tostring = function(s)
                local subs = ""
                for _, v in pairs(s.vars) do subs = subs..v[1].."," end
                subs = subs:sub(1,#subs-1)
                return "<structDef-"..s.name.."("..subs..")>"
            end }
    )
end
Struct = function(structName, varAddrs)
    return setmetatable(
            { name = structName, varAddrs = varAddrs,
              copy = function(s) return Struct(s.name, copy(s.varAddr)) end,
              setAddr = function(s, node, name, addr, memory)
                  local value, err = s:get(name) if err then return nil, err end
                  return nil, Error("name error", "name '"..name.."' cannot be found", node.pr:copy())
              end,
              getAddr = function(s, node, name)
                  local scope
                  for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                  if scope then
                      return scope.vars[name]
                  end
                  return nil, Error("name error", "name '"..name.."' cannot be found", node.pr:copy())
              end,
            },
            { __name = "Struct", __tostrings = function(s)
                local subs = ""
                for k, addr in pairs(s.varAddrs) do subs = subs..k.."="..tostring(addr).."," end
                subs = subs:sub(1,#subs-1)
                return "<struct-"..s.name.."("..subs..")>"
            end }
    )
end

local function Memory(memory)
    if not memory then memory = {} end
    return setmetatable(memory, { __name = "Memory", __index = function(s,k)
        if k == "new" then return function(self) return #self+1 end end
        return rawget(s, k)
    end })
end
-- built-in funcitons
local MEMORY MEMORY = Memory({
    -- print
    LuaFunc({ "value" }, function(_, _, args)
        print(str(args[1]))
        return Null()
    end, Type("null")),
    -- debugMem
    LuaFunc({ }, function()
        print("\n- memory -")
        for i = 6, #MEMORY do print(i, str(MEMORY[i],true)) end
        print()
        return Null()
    end, Type("null")),
    -- debugScopes
    LuaFunc({ }, function(scopes)
        print("- scopes -")
        for i, scope in ipairs(scopes.scopes) do print(scope.label, str(scope.vars)) end
        print()
        return Null()
    end, Type("null")),
    -- fromAddr
    LuaFunc({ "addr" }, function(_, node, args)
        if type(args[1]) ~= "Number" then return nil, false, Error("lua func error", "expected Number as #1 argument", node.pr:copy()) end
        if not MEMORY[math.floor(args[1].value)] then return nil, false, Error("lua func error", "memory addres "..str(args[1]).." doesn't exist", node.pr:copy()) end
        return MEMORY[math.floor(args[1].value)]:copy()
    end),
    -- setAddr
    LuaFunc({ "var", "addr" }, function(scopes, node, args)
        if type(args[1]) ~= "String" then return nil, false, Error("lua func error", "expected String as #1 argument", node.pr:copy()) end
        if type(args[2]) ~= "Number" then return nil, false, Error("lua func error", "expected Number as #2 argument", node.pr:copy()) end
        local _, err = scopes:setAddr(node, args[1].value, args[2].value, MEMORY) if err then return nil, false, err end
        return Null()
    end, Type("null")),
})
local function Scope(vars, label)
    if not label then label = "<sub>" end
    if not vars then vars = {} end
    return setmetatable(
            { vars = vars, label = label, copy = function(s) return Scope(copy(s.vars)) end,
              get = function(s, name) return s.vars[name] end,
              set = function(s, name, addr) s.vars[name] = addr end
            },
            { __name = "Scope", __tostring = function(s)
                return "Scope("..str(s.vars)..")"
            end }
    )
end
local function Scopes(scopes)
    if not scopes then scopes = {} end
    return setmetatable(
            { scopes = scopes, copy = function(s)
                local a = {}
                for i, v in ipairs(s.scopes) do a[i] = v:copy() end
                return Scopes(a)
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
                if scope then
                    return scope.vars[name]
                end
                return nil, Error("name error", "name '"..name.."' cannot be found", node.pr:copy())
            end, get = function(s, node, memory)
                local name = node
                if type(node) ~= "string" then name = node.args[1].value end
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if scope then
                    local addr = scope:get(name)
                    if memory[addr] then return memory[addr] end
                    return nil, Error("name error", "address of '"..name.."' doesn't exist in memory", node.pr:copy())
                end
                return nil, Error("name error", "name '"..name.."' is not registered", node.pr:copy())
            end, set = function(s, nameNode, value, memory)
                local name = nameNode
                if type(nameNode) ~= "string" then name = nameNode.args[1].value end
                local addr, err
                local scope
                for _, v in ipairs(s.scopes) do if v:get(name) then scope=v end end
                if not scope then
                    scope = s.scopes[#s.scopes]
                    addr, err = memory:new() if err then return nil, err end
                else addr = scope.vars[name] end
                scope:set(name, addr)
                memory[addr] = value
                return addr
            end,
              new = function(s, scope) s.scopes[#s.scopes+1] = scope end,
              --TODO: garbage collector
              drop = function(s) pop(s.scopes) end
            },
            { __name = "Scopes", __tostring = function(s)
                return "Scopes("..str(s.scopes)..")"
            end }
    )
end

local function stdScope()
    local scopes = Scopes({ Scope() })
    scopes.scopes[1].vars["print"] = 1
    scopes.scopes[1].vars["debugMem"] = 2
    scopes.scopes[1].vars["debugScopes"] = 3
    scopes.scopes[1].vars["fromAddr"] = 4
    scopes.scopes[1].vars["setAddr"] = 5
    return scopes
end

local function interpret(ast)
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
        if words.type[type_.value] then return words.type[type_.value] end
        if type(type_) == "Struct" then return type_.name end
        if contains(words.type, type(type_)) then return type(type_) end
        local value, err = scopes:get(type_.name, MEMORY) if err then return end
        if type(value) == "StructDef" then return value.name end
    end
    nodes = {
        notImplemented = function(node) return nil, false, Error("not implemented", node.name, node.pr:copy()) end,
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
                local addr addr, _, err = nodes.indexAddr(node.args[1]) if err then return nil, false, err end
                addr = addr.value
                if typeOfType(MEMORY[addr]) ~= typeOfType(value) then
                    return nil, false, Error("value error", "expected "..typeOfType(MEMORY[addr])..", got "..typeOfType(value), node.args[2].pr:copy())
                end
                MEMORY[addr] = value:copy()
                return value
            elseif node.args[1].name == "name" then
                local addr addr, err = scopes:set(node.args[1], value, MEMORY) if err then return nil, false, err end
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
            if type_.value == "type" then castValue = Type(type(value)) end
            if type_.value == "null" then castValue = Null() end
            if type_.value == "number" then castValue = value:toNumber() end
            if type_.value == "bool" then castValue = value:toBool() end
            if type_.value == "string" then castValue = value:toString() end
            if type_.value == "list" then castValue = value:toList() end
            if not castValue then return nil, false, Error("cast error", "cannot cast "..type(value).." to "..typeOfType(type_), node.pr:copy()) end
            return castValue
        end,
        index = function(node)
            if node.args[3].name ~= "name" then return nil, false, Error("index error", "expected name", node.args[3].pr:copy()) end
            local head, index, addr, err
            --TODO: weird varAddrs not in head bug
            head, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(head) ~= "Struct" then return nil, false, Error("index error", "cannot index "..type(head), node.args[2].pr:copy()) end
            index = node.args[3].args[1].value
            print(str(head), index)
            addr = head.varAddrs[index]
            if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not in '"..head.name.."'", node.pr:copy()) end
            if not MEMORY[addr] then return nil, false, Error("memory error", "address "..str(addr).." doesn't exists", node.pr:copy()) end
            return MEMORY[addr]
        end,
        indexAddr = function(node)
            if node.args[3].name ~= "name" then return nil, false, Error("index error", "expected name", node.args[3].pr:copy()) end
            local head, index, addr, err
            head, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(head) ~= "Struct" then return nil, false, Error("index error", "cannot index "..type(head), node.args[2].pr:copy()) end
            index = node.args[3].args[1].value
            addr = head.varAddrs[index]
            if addr == nil then return nil, false, Error("index error", "index '"..index.."' is not in '"..head.name.."'", node.pr:copy()) end
            return Number(addr)
        end,
        idxList = function(node)
            local list, index, err
            list, _, err = visit(node.args[1]) if err then return nil, false, err end
            index, _, err = visit(node.args[2]) if err then return nil, false, err end
            if type(list) == "List" then
                if type(index) == "Number" then
                    local value = list.values[math.floor(index.value)+1]
                    if value == nil then return nil, false, Error("index error", "index out of range", node.pr:copy()) end
                    return value:copy()
                end
                if type(index) == "Range" then
                    local value = List(sub(list.values, index.start+1, index.stop+1))
                    return value:copy()
                end
            end
            if type(list) == "Range" then
                if type(index) == "Number" then
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
                if opTok.value == "not" then if type(value) == "Bool" then return Bool(not value.value) end end
            end
        end,
        body = function(node, name, breakable, skippable)
            scopes:new(Scope(nil, name))
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
                    scopes:set(nameNode, Number(i), MEMORY)
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
                    scopes:new(Scope({}, "iterator"))
                    scopes:set(nameNode, x:copy(), MEMORY)
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
            local type_, err if node.args[4] then
                type_, _, err = visit(node.args[4]) if err then return nil, false, err end
                if type(type_) ~= "Type" then return nil, false, Error("value error", "expected Type", node.args[4].pr:copy()) end
            end
            local func = Func(node.args[2], node.args[3], type_)
            local addr addr, err = scopes:set(node.args[1], func, MEMORY) if err then return nil, false, err end
            return func
        end,
        call = function(node)
            local func, args, err = nil, {}
            func, _, err = visit(node.args[1]) if err then return nil, false, err end
            if type(func) == "Func" then
                for _, arg in ipairs(node.args[2]) do
                    local value
                    value, __, err = visit(arg) if err then return nil, false, err end
                    push(args, value)
                end
                local value
                local mainScopes = scopes
                scopes = stdScope()
                scopes:new(Scope({}, "func"))
                for i, var in ipairs(func.vars) do
                    if not args[i] then return nil, false, Error("func error", "too few arguments", node.pr:copy()) end
                    _, err = scopes:set(var, args[i], MEMORY) if err then return nil, false, err end
                end
                value, _, err = visit(func.body) if err then return nil, false, err end
                scopes = mainScopes
                if func.returnType then
                    if type(value) ~= typeOfType(func.returnType) then
                        return nil, false, Error("func error", "returned value isn't "..str(typeOfType(func.returnType))..", got "..type(value), node.pr:copy())
                    end
                end
                return value
            end
            if type(func) == "LuaFunc" then
                for _, arg in ipairs(node.args[2]) do
                    local value
                    value, __, err = visit(arg) if err then return nil, false, err end
                    push(args, value)
                end
                local value
                local mainScopes = scopes
                scopes = stdScope()
                scopes:new(Scope({}, "lua-func"))
                for i, var in ipairs(func.vars) do
                    if not args[i] then return nil, false, Error("func error", "too few arguments", node.pr:copy()) end
                    _, err = scopes:set(var, args[i], MEMORY) if err then return nil, false, err end
                end
                value, _, err = func.func(scopes, node, args) if err then return nil, false, err end
                scopes = mainScopes
                if func.returnType then if type(value) ~= typeOfType(func.returnType) then
                        return nil, false, Error("func error", "returned value isn't "..str(typeOfType(func.returnType))..", got "..type(value), node.pr:copy())
                end end
                return value
            end
            if type(func) == "StructDef" then
                for _, arg in ipairs(node.args[2]) do
                    local value value, __, err = visit(arg) if err then return nil, false, err end
                    push(args, value)
                end
                local varAddrs = {}
                for i, varDef in ipairs(func.vars) do
                    if not args[i] then return nil, false, Error("func error", "too few arguments", node.pr:copy()) end
                    if varDef[2] then if typeOfType(args[i]) ~= typeOfType(varDef[2]) then
                        return nil, false, Error("value error", "expected type "..typeOfType(varDef[2]).." for '"..varDef[1].."', got "..type(args[i]),
                                node.pr:copy())
                    end end
                    local addr addr, err = MEMORY:new() if err then return nil, false, err end
                    MEMORY[addr] = args[i]
                    varAddrs[varDef[1]] = addr
                end
                print(str(varAddrs))
                return Struct(func.name, varAddrs)
            end
            return nil, false, Error("value error", "expected Func/LuaFunc/StructDef", node.args[1].pr:copy())
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
        struct = function(node)
            local nameNode, nodeVars, err = node.args[1], node.args[2]
            local name, vars = nameNode.args[1].value, {}
            for _, varDef in ipairs(nodeVars) do
                local var = varDef[1]
                local type_ type_, _, err = visit(varDef[2]) if err then return nil, false, err end
                push(vars, { var.args[1].value, type_ })
            end
            scopes:set(name,StructDef(name, vars),MEMORY)
            return scopes:get(name, MEMORY)
        end
    }
    visit = function(node, ...)
        if not node then error("no node given", 2) end
        if nodes[node.name] then return nodes[node.name](node, ...) end
        return nodes.notImplemented(node)
    end
    if not ast then return Null() end
    local value, returning, err = visit(ast) if err then return nil, false, err end
    if not getmetatable(value) then return nil, false, Error("dev error", "value returned is not a metatable") end
    return value
end

--TODO: check if all errors work

return {
    lex = lex, parse = parse, interpret = interpret,
    Number = Number, Bool = Bool, String = String, Type = Type, Null = Null, List = List, Range = Range,
    Func = Func, LuaFunc = LuaFunc, Memory = Memory, Scope = Scope, Scopes = Scopes,
    Token = Token, Node = Node,
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
            if ast.name == "struct" then
                local str_ = "(struct " .. s(s,ast.args[1]) .. " ("
                for _, node in ipairs(ast.args[2]) do
                    if node[2] then str_ = str_ .. s(s,node[1]) .. " : " .. s(s,node[2]) .. ", "
                    else str_ = str_ .. s(s,node[1]) .. ", " end
                end
                return str_:sub(1,#str_-2) .. ") end)"
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