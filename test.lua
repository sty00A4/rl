local make = require "make"
local tokens, ast, value, vars, returning, err
local text = io.open("test.txt", "r"):read("*a")
tokens, err = make.lex("test.txt", text) if err then print(err) return end
--if #tokens > 0 then for _, t in ipairs(tokens) do io.write(tostring(t)," ") end print("\n") end
ast, err = make.parse(tokens) if err then print(err) return end
--print(make.ast2str(make.ast2str, ast))
value, returning, err = make.interpret(ast) if err then print(err) return end
if value.value ~= nil then print(value) end