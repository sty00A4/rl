os.clock()
local rl = require "rl"
local tokens, ast, value, returning, err
local detail = false
local text = io.open("test.rl", "r"):read("*a")
tokens, err = rl.lex("test.rl", text) if err then print(err) return end
--if #tokens > 0 then for _, t in ipairs(tokens) do io.write(tostring(t)," ") end print("\n") end
ast, err = rl.parse(tokens) if err then print(err) return end
if ast then
    --print(rl.ast2str(rl.ast2str, ast))
    value, returning, err = rl.interpret(ast) if err then print(err) return end
    if returning or ast.name ~= "body" then print(value) end
end