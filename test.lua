local erl = require "erl"
local tokens, ast, value, vars, returning, err
local text = io.open("test.txt", "r"):read("*a")
tokens, err = erl.lex("test.txt", text) if err then print(err) return end
--if #tokens > 0 then for _, t in ipairs(tokens) do io.write(tostring(t)," ") end print("\n") end
ast, err = erl.parse(tokens) if err then print(err) return end
--print(erl.ast2str(erl.ast2str, ast))
value, returning, err = erl.interpret(ast) if err then print(err) return end
if value.value ~= nil then print(value) end